using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

namespace Pulse.Services;

/// <summary>
/// Remembers agent tokens between runs. Tokens are encrypted with Windows DPAPI (tied to your
/// Windows login) and saved to %LOCALAPPDATA%\Pulse\agents.json as { symbol: base64-ciphertext }.
/// </summary>
public sealed class CredentialStore
{
    private static readonly string FilePath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Pulse", "agents.json");

    public IReadOnlyList<string> GetSymbols() => Load().Keys.Order().ToList();

    public string? GetToken(string symbol)
    {
        if (!Load().TryGetValue(symbol, out var b64)) return null;   // "out var" declares the result inline
        try
        {
            var plain = ProtectedData.Unprotect(Convert.FromBase64String(b64), null, DataProtectionScope.CurrentUser);
            return Encoding.UTF8.GetString(plain);
        }
        catch (CryptographicException) { return null; }               // e.g. file copied from another PC/user
    }

    public void Save(string symbol, string token)
    {
        var all = Load();
        var cipher = ProtectedData.Protect(Encoding.UTF8.GetBytes(token), null, DataProtectionScope.CurrentUser);
        all[symbol] = Convert.ToBase64String(cipher);
        Directory.CreateDirectory(Path.GetDirectoryName(FilePath)!);
        File.WriteAllText(FilePath, JsonSerializer.Serialize(all));
    }

    private static Dictionary<string, string> Load()
    {
        try
        {
            return File.Exists(FilePath)
                ? JsonSerializer.Deserialize<Dictionary<string, string>>(File.ReadAllText(FilePath)) ?? new()
                : new();                                              // "new()" = target-typed constructor
        }
        catch (JsonException) { return new(); }
    }
}
