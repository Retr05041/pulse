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
public record Cargo(int Units, int Capacity, IReadOnlyList<CargoItem> Inventory);
public record CargoItem(
    string Symbol,
    string Name,
    string Description,
    int Units
);

// Top-level Contract model
public record Contract(
    string Id,
    string FactionSymbol,
    string Type,
    ContractTerms Terms,
    bool Accepted,
    bool Fulfilled,
    DateTimeOffset DeadlineToAccept
);

// Inner nested contract objects
public record ContractTerms(
    DateTimeOffset Deadline,
    ContractPayment Payment,
    IReadOnlyList<ContractDeliver> Deliver
);

public record ContractPayment(
    long OnAccepted,
    long OnFulfilled
);

public record ContractDeliver(
    string TradeSymbol,
    string DestinationSymbol,
    int UnitsRequired,
    int UnitsFulfilled
);

// Request payload for delivering contract cargo
public record DeliverContractRequest(
    string ShipSymbol,
    string TradeSymbol,
    int Units
);

// Response payload wrapper containing updated contract and ship cargo
public record DeliverContractResponse(
    Contract Contract,
    Cargo Cargo
);

// Simple record used to display options in the ship dropdown selector
public record ShipCargoOption(string ShipSymbol, int AvailableUnits, string Waypoint)
{
    public string DisplayText => $"{ShipSymbol} ({AvailableUnits} units at {Waypoint})";
}