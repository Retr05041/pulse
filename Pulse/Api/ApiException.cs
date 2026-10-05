using System.Net;
using System.Text.Json;

namespace Pulse.Api;

/// <summary>A SpaceTraders error response, e.g. { "error": { "message": "...", "code": 4000 } }.</summary>
public sealed class ApiException : Exception
{
    public HttpStatusCode Status { get; }
    public int? Code { get; }

    public ApiException(HttpStatusCode status, int? code, string message) : base(message)
    {
        Status = status;
        Code = code;
    }

    // Parses the error body if possible; falls back to the raw text. (Your PS version
    // never surfaced this message - it lived in $_.ErrorDetails.)
    public static ApiException From(HttpStatusCode status, string body)
    {
        try
        {
            using var doc = JsonDocument.Parse(body);
            var err = doc.RootElement.GetProperty("error");
            int? code = err.TryGetProperty("code", out var c) ? c.GetInt32() : null;
            return new ApiException(status, code, err.GetProperty("message").GetString() ?? body);
        }
        catch (Exception ex) when (ex is JsonException or KeyNotFoundException)
        {
            return new ApiException(status, null, $"HTTP {(int)status}: {body}");
        }
    }
}
