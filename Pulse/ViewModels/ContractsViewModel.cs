using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Pulse.Services;

namespace Pulse.ViewModels;

public partial class ContractsViewModel : ObservableObject, IDisposable
{
    private readonly Session _session;
    private readonly PulseService _pulse;
    private readonly Action _onBack;

    public string AgentSymbol => _session.Agent.Symbol;
    public string CurrentSystem => _session.Agent.Headquarters; // Or wherever current location/system is tracked
    public ObservableCollection<ContractViewModel> Contracts { get; } = new();

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
        Status = "Loading contracts...";
        try
        {
            var contracts = await _session.Client.Contracts.GetContractsAsync();
            Contracts.Clear();
            foreach (var contract in contracts)
            {
                Contracts.Add(new ContractViewModel(contract, _session));
            }
            Status = $"{Contracts.Count} contract{(Contracts.Count == 1 ? "" : "s")}";
        }
        catch (Exception ex)
        {
            Status = ex.Message;
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