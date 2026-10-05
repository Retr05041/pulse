using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;

namespace Pulse.Api;

/// <summary>
/// The only class that talks HTTP. One instance per logged-in agent (it holds the token).
/// Adding an endpoint = one new line that calls GetAsync / GetAllPagesAsync.
/// </summary>
public sealed class SpaceTradersClient : IDisposable
{
    // Web defaults = camelCase names + case-insensitive matching, which is what the API uses.
    private static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);

    private readonly HttpClient _http;
    // ~2 requests/sec sustained is the documented limit; 550ms spacing leaves a safety margin.
    // (The API also allows short bursts; this simple version doesn't exploit them. Check the docs.)
    private readonly RequestScheduler _scheduler = new(TimeSpan.FromMilliseconds(550));

    public SpaceTradersClient(string token)
    {
        _http = new HttpClient { BaseAddress = new Uri("https://api.spacetraders.io/v2/") };
        _http.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
    }

    // ---- Endpoints ----------------------------------------------------------------------
    public Task<Agent> GetAgentAsync(RequestPriority p = RequestPriority.Interactive)
        => GetAsync<Agent>("my/agent", p);

    public Task<List<Ship>> GetShipsAsync(RequestPriority p = RequestPriority.Interactive)
        => GetAllPagesAsync<Ship>("my/ships", p);

    // ---- Plumbing -----------------------------------------------------------------------

    // Single resource: queue it, send it, unwrap { "data": ... }.
    private async Task<T> GetAsync<T>(string path, RequestPriority p)
    {
        var env = await _scheduler.EnqueueAsync(() => SendAsync<Envelope<T>>(HttpMethod.Get, path), p);
        return env.Data;
    }

    // Paged list: keep requesting pages until we have meta.total items. Each page is its own
    // queued request, so an Interactive call can slip in between pages of a Background fetch.
    private async Task<List<T>> GetAllPagesAsync<T>(string path, RequestPriority p)
    {
        var all = new List<T>();
        for (var page = 1; ; page++)
        {
            var url = $"{path}?page={page}&limit=20";      // $"..." = string interpolation
            var env = await _scheduler.EnqueueAsync(() => SendAsync<Envelope<List<T>>>(HttpMethod.Get, url), p);
            all.AddRange(env.Data);
            if (env.Data.Count == 0 || env.Meta is null || all.Count >= env.Meta.Total) return all;
        }
    }

    // Runs INSIDE the scheduler's pump, so sleeping here on a 429 correctly pauses ALL requests.
    private async Task<T> SendAsync<T>(HttpMethod method, string path, object? body = null)
    {
        for (var attempt = 0; ; attempt++)
        {
            using var request = new HttpRequestMessage(method, path);   // "using" = auto-dispose at scope end
            if (body is not null) request.Content = JsonContent.Create(body, options: Json);

            using var response = await _http.SendAsync(request);

            if (response.StatusCode == (HttpStatusCode)429 && attempt < 3)
            {
                // Rate limited anyway: obey Retry-After (default 2s) and try again.
                await Task.Delay(response.Headers.RetryAfter?.Delta ?? TimeSpan.FromSeconds(2));
                continue;
            }

            var text = await response.Content.ReadAsStringAsync();
            if (!response.IsSuccessStatusCode) throw ApiException.From(response.StatusCode, text);
            return JsonSerializer.Deserialize<T>(text, Json)!;          // "!" = "trust me, not null"
        }
    }

    public void Dispose()
    {
        _scheduler.Dispose();
        _http.Dispose();
    }
}
