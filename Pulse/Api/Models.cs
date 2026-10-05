namespace Pulse.Api;

// A "record" is an immutable data class with auto-generated constructor, equality and ToString.
// Properties are PascalCase here; the JSON options in SpaceTradersClient map them to the
// API's camelCase automatically. Add fields as you need them; unknown JSON fields are ignored.

public record Envelope<T>(T Data, Meta? Meta);          // every API response: { "data": ..., "meta": ... }
public record Meta(int Total, int Page, int Limit);      // pagination info ("?" = may be null)

public record Agent(string Symbol, string StartingFaction, long Credits, string Headquarters);

public record Ship(string Symbol, Nav Nav, Fuel Fuel, Cargo Cargo);
public record Nav(string SystemSymbol, string WaypointSymbol, string Status, Route Route);
public record Route(DateTimeOffset Arrival);             // when an in-transit ship lands
public record Fuel(int Current, int Capacity);
public record Cargo(int Units, int Capacity);
