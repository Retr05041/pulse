using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Pulse.Api;
using Pulse.Services;

namespace Pulse.ViewModels;
// CHANGED: Enhanced DeliverItemViewModel to support selecting a ship and delivering cargo
public partial class DeliverItemViewModel : ObservableObject
{
    private readonly ContractDeliver _deliver;
    private readonly string _contractId;
    private readonly Session _session;
    private readonly Func<Task> _onRefreshRequested;

    public string TradeSymbol => _deliver.TradeSymbol;
    public string DestinationSymbol => _deliver.DestinationSymbol;
    public int UnitsRequired => _deliver.UnitsRequired;
    public int UnitsFulfilled => _deliver.UnitsFulfilled;
    public double ProgressPercent => UnitsRequired > 0 ? (UnitsFulfilled * 100.0 / UnitsRequired) : 0;
    public string ProgressText => $"{UnitsFulfilled:N0} / {UnitsRequired:N0}";

    // Holds eligible ships currently carrying matching cargo
    public ObservableCollection<ShipCargoOption> AvailableShips { get; } = new();

    [ObservableProperty] private ShipCargoOption? _selectedShip;
    [ObservableProperty] private string _deliveryStatus = "";
    [ObservableProperty] private bool _isDelivering;

    public DeliverItemViewModel(ContractDeliver deliver, string contractId, Session session, List<Ship> fleet, Func<Task> onRefreshRequested)
    {
        _deliver = deliver;
        _contractId = contractId;
        _session = session;
        _onRefreshRequested = onRefreshRequested;

        // Filter ships that have this resource in cargo
        foreach (var ship in fleet)
        {
            var cargoItem = ship.Cargo.Inventory.FirstOrDefault(i => i.Symbol == _deliver.TradeSymbol);
            if (cargoItem != null && cargoItem.Units > 0)
            {
                AvailableShips.Add(new ShipCargoOption(ship.Symbol, cargoItem.Units, ship.Nav.WaypointSymbol));
            }
        }

        SelectedShip = AvailableShips.FirstOrDefault();
    }

    [RelayCommand(CanExecute = nameof(CanDeliver))]
    private async Task DeliverCargoAsync()
    {
        if (SelectedShip == null) return;

        IsDelivering = true;
        DeliveryStatus = "Delivering...";
        try
        {
            await _session.Client.Contracts.DeliverContractAsync(
                _contractId,
                SelectedShip.ShipSymbol,
                TradeSymbol,
                SelectedShip.AvailableUnits
            );

            DeliveryStatus = "Delivered!";
            await _onRefreshRequested();
        }
        catch (Exception ex)
        {
            DeliveryStatus = ex.Message;
        }
        finally
        {
            IsDelivering = false;
        }
    }

    private bool CanDeliver() => SelectedShip != null && !IsDelivering;
}