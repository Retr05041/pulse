using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Pulse.Api;
using Pulse.Services;

namespace Pulse.ViewModels;

public partial class ContractsViewModel : ObservableObject, IDisposable
{
    private readonly Session _session;
    private readonly PulseService _pulse;
    private readonly Action _onBack;

    public string AgentSymbol => _session.Agent.Symbol;
    public string CurrentSystem => _session.Agent.Headquarters;

    public ObservableCollection<ContractViewModel> Contracts { get; } = new();

    // Added collection to track ships eligible to negotiate new contracts
    public ObservableCollection<Ship> EligibleNegotiatorShips { get; } = new();

    [ObservableProperty] private string _status = "";

    public ContractsViewModel(Session session, PulseService pulse, Action onBack)
    {
        _session = session;
        _pulse = pulse;
        _onBack = onBack;

        _pulse.Tick += OnTick;
        _ = RefreshAsync();
    }

    [RelayCommand]
    private async Task RefreshAsync()
    {
        Status = "Loading contracts and fleet data...";
        try
        {
            // Fetch ships alongside contracts to feed cargo delivery & negotiation options
            var contractsTask = _session.Client.Contracts.GetContractsAsync();
            var shipsTask = _session.Client.Fleet.GetShipsAsync();

            await Task.WhenAll(contractsTask, shipsTask);

            var contracts = contractsTask.Result;
            var ships = shipsTask.Result.ToList();

            // Populate contracts
            Contracts.Clear();
            foreach (var contract in contracts)
            {
                Contracts.Add(new ContractViewModel(contract, _session, ships, RefreshAsync));
            }

            // Filter docked ships for contract negotiation capability
            EligibleNegotiatorShips.Clear();
            foreach (var ship in ships.Where(s => s.Nav.Status == "DOCKED"))
            {
                EligibleNegotiatorShips.Add(ship);
            }

            Status = $"{Contracts.Count} contract{(Contracts.Count == 1 ? "" : "s")}";
        }
        catch (Exception ex)
        {
            Status = ex.Message;
        }
    }

    // Added command to handle negotiate requests for a specific ship symbol
    [RelayCommand]
    private async Task NegotiateContractAsync(string shipSymbol)
    {
        if (string.IsNullOrEmpty(shipSymbol)) return;

        Status = $"Negotiating contract with {shipSymbol}...";
        try
        {
            await _session.Client.Contracts.NegotiateNewContractAsync(shipSymbol);
            Status = "New contract negotiated!";
            await RefreshAsync(); // Refresh list after acquiring contract
        }
        catch (Exception ex)
        {
            Status = $"Negotiation failed: {ex.Message}";
        }
    }

    [RelayCommand]
    private void Back() => _onBack();

    private void OnTick(DateTimeOffset now)
    {
        foreach (var contract in Contracts)
        {
            contract.Tick(now);
        }
    }

    public void Dispose()
    {
        _pulse.Tick -= OnTick;
    }
}