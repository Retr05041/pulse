using Pulse.Api;

namespace Pulse.Services;

/// <summary>What a successful login produces. Replaces passing (symbol, token, agent) everywhere.</summary>
public sealed record Session(SpaceTradersClient Client, Agent Agent);
