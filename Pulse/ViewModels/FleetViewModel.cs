using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Pulse.Services;

namespace Pulse.ViewModels;

public partial class FleetViewModel : ObservableObject, IDisposable
{
    private readonly Session _session;
    private readonly PulseService _pulse;
    private readonly Action _onBack;

    public string AgentSymbol => _session.Agent.Symbol;
    public string CreditsText => $"{_session.Agent.Credits:N0} credits";   // TODO: refresh periodically
    public ObservableCollection<ShipViewModel> Ships { get; } = new();

    [ObservableProperty] private string _status = "";

    public FleetViewModel(Session session, PulseService pulse, Action onBack)
    {
        _session = session;
        _pulse = pulse;
        _onBack = onBack;

        _pulse.Tick += OnTick;                  // subscribe to the heartbeat
        _ = RefreshAsync();                     // kick off the first load; the UI shows immediately
    }

    // Generates RefreshCommand. Catches its own errors, so fire-and-forget above is safe.
    [RelayCommand]
    private async Task RefreshAsync()
    {
        Status = "Loading fleet...";
        try
        {
            var ships = await _session.Client.Fleet.GetShipsAsync();
            Ships.Clear();
            foreach (var ship in ships) Ships.Add(new ShipViewModel(ship));
            Status = $"{Ships.Count} ship{(Ships.Count == 1 ? "" : "s")}";
        }
        catch (Exception ex) { Status = ex.Message; }
    }

    [RelayCommand]
    private void Back() => _onBack();

    private void OnTick(DateTimeOffset now)
    {
        foreach (var ship in Ships) ship.Tick(now);   // update countdowns locally, no API calls
    }

    // Called by ShellViewModel when we navigate away. Forgetting "-=" is a classic event leak.
    public void Dispose()
    {
        _pulse.Tick -= OnTick;
    }
}
