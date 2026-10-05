using CommunityToolkit.Mvvm.ComponentModel;
using Pulse.Api;

namespace Pulse.ViewModels;

/// <summary>Display wrapper around one Ship: pre-computed text/percentages the card binds to.</summary>
public partial class ShipViewModel : ObservableObject
{
    private readonly Ship _ship;

    public string Symbol => _ship.Symbol;
    public string Status => _ship.Nav.Status;                       // DOCKED / IN_ORBIT / IN_TRANSIT
    public string Location => _ship.Nav.WaypointSymbol;
    public double FuelPercent => Percent(_ship.Fuel.Current, _ship.Fuel.Capacity);
    public string FuelText => _ship.Fuel.Capacity > 0 ? $"{_ship.Fuel.Current:N0} / {_ship.Fuel.Capacity:N0}" : "No fuel";
    public double CargoPercent => Percent(_ship.Cargo.Units, _ship.Cargo.Capacity);
    public string CargoText => $"{_ship.Cargo.Units:N0} / {_ship.Cargo.Capacity:N0} units";

    [ObservableProperty] private string _etaText = "";              // changes every second while in transit

    public ShipViewModel(Ship ship)
    {
        _ship = ship;
        Tick(DateTimeOffset.UtcNow);
    }

    // Driven by PulseService: compute the countdown from the arrival timestamp.
    public void Tick(DateTimeOffset now)
    {
        if (_ship.Nav.Status != "IN_TRANSIT") { EtaText = ""; return; }
        var left = _ship.Nav.Route.Arrival - now;
        EtaText = left > TimeSpan.Zero ? $"arrives in {(int)left.TotalMinutes}:{left.Seconds:00}" : "arriving...";
        // TODO: when this hits zero, re-fetch just this ship (Background priority).
    }

    private static double Percent(int value, int max) => max > 0 ? Math.Clamp(value * 100.0 / max, 0, 100) : 0;
}
