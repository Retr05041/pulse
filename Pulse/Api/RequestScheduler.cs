using System.Diagnostics;

namespace Pulse.Api;

public enum RequestPriority { Interactive = 0, Background = 1 }   // lower number = served first

/// <summary>
/// Funnels every API call through ONE queue so we never exceed the rate limit, and so a user
/// click jumps ahead of background polling. A single loop ("pump") runs jobs one at a time and
/// waits at least <c>minInterval</c> between them.
/// </summary>
public sealed class RequestScheduler : IDisposable
{
    // Priority = (priority level, sequence number). The sequence keeps FIFO order within a level.
    private readonly PriorityQueue<Func<Task>, (int, long)> _queue = new();
    private readonly object _lock = new();                 // PriorityQueue isn't thread-safe
    private readonly SemaphoreSlim _signal = new(0);       // counts queued jobs; pump sleeps on it
    private readonly CancellationTokenSource _cts = new();
    private readonly TimeSpan _minInterval;
    private long _sequence;

    public RequestScheduler(TimeSpan minInterval)
    {
        _minInterval = minInterval;
        _ = Task.Run(PumpAsync);                           // "_ =" = deliberately fire-and-forget
    }

    /// <summary>Queue work; the returned Task completes when the pump has run it.</summary>
    public Task<T> EnqueueAsync<T>(Func<Task<T>> work, RequestPriority priority = RequestPriority.Interactive)
    {
        // TaskCompletionSource = a Task we complete manually. The caller awaits it while the
        // pump does the real work later and sets the result (or exception) on it.
        var tcs = new TaskCompletionSource<T>(TaskCreationOptions.RunContinuationsAsynchronously);

        Func<Task> job = async () =>
        {
            try { tcs.SetResult(await work()); }
            catch (Exception ex) { tcs.SetException(ex); }
        };

        lock (_lock) _queue.Enqueue(job, ((int)priority, _sequence++));
        _signal.Release();                                 // wake the pump
        return tcs.Task;
    }

    private async Task PumpAsync()
    {
        try
        {
            while (true)
            {
                await _signal.WaitAsync(_cts.Token);       // sleep until there is work
                Func<Task> job;
                lock (_lock) job = _queue.Dequeue();       // highest-priority job

                var start = Stopwatch.GetTimestamp();
                await job();                               // one request at a time

                var remaining = _minInterval - Stopwatch.GetElapsedTime(start);
                if (remaining > TimeSpan.Zero) await Task.Delay(remaining, _cts.Token);
            }
        }
        catch (OperationCanceledException) { /* Dispose() was called: exit quietly */ }
    }

    public void Dispose() => _cts.Cancel();
}
