using System.Windows.Threading;

namespace Pulse.Services;

/// <summary>
/// The app's heartbeat: one 1-second ticker. View models subscribe to <see cref="Tick"/> to
/// update countdowns locally instead of polling the server. Future routines/schedulers can
/// hang off this too.
/// </summary>
public sealed class PulseService
{
    // DispatcherTimer fires on the UI thread, so subscribers may touch bound properties safely.
    private readonly DispatcherTimer _timer = new() { Interval = TimeSpan.FromSeconds(1) };

    // An "event" lets other classes subscribe with += and unsubscribe with -=.
    public event Action<DateTimeOffset>? Tick;

    public PulseService()
    {
        _timer.Tick += (_, _) => Tick?.Invoke(DateTimeOffset.UtcNow);   // "?." = call only if not null
        _timer.Start();
    }
}
