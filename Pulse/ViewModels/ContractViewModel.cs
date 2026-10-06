using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Pulse.Api;
using Pulse.Services;
using Pulse.Api.Endpoints;

namespace Pulse.ViewModels;

/// <summary>Display wrapper around one Contract: pre-computed text, state, and actions.</summary>
public partial class ContractViewModel : ObservableObject
{
    private readonly Contract _contract;
    private readonly Session _session;

    public string Id => _contract.Id;
    public string FactionSymbol => _contract.FactionSymbol;
    public string Type => _contract.Type;

    public string PaymentText => $"{_contract.Terms.Payment.OnAccepted:N0} up front / {_contract.Terms.Payment.OnFulfilled:N0} on completion";
    public string TotalPaymentText => $"{(_contract.Terms.Payment.OnAccepted + _contract.Terms.Payment.OnFulfilled):N0} total credits";

    public IReadOnlyList<DeliverItemViewModel> Deliveries { get; }

    [ObservableProperty] private bool _isAccepted;
    [ObservableProperty] private bool _isFulfilled;
    [ObservableProperty] private string _deadlineText = "";
    [ObservableProperty] private string _statusMessage = "";
    [ObservableProperty] private bool _isBusy;

    public ContractViewModel(Contract contract, Session session)
    {
        _contract = contract;
        _session = session;

        _isAccepted = contract.Accepted;
        _isFulfilled = contract.Fulfilled;

        Deliveries = contract.Terms.Deliver
            .Select(d => new DeliverItemViewModel(d))
            .ToList();

        Tick(DateTimeOffset.UtcNow);
    }

    public void Tick(DateTimeOffset now)
    {
        var deadline = IsAccepted ? _contract.Terms.Deadline : _contract.DeadlineToAccept;
        var left = deadline - now;

        if (left <= TimeSpan.Zero)
        {
            DeadlineText = IsAccepted ? "Expired" : "Accept window expired";
        }
        else if (left.TotalHours >= 24)
        {
            DeadlineText = $"{left.Days}d {left.Hours}h remaining";
        }
        else
        {
            DeadlineText = $"{(int)left.TotalHours:00}:{left.Minutes:00}:{left.Seconds:00}";
        }
    }

    [RelayCommand(CanExecute = nameof(CanAccept))]
    private async Task AcceptAsync()
    {
        IsBusy = true;
        StatusMessage = "Accepting...";
        try
        {
            var updatedContract = await _session.Client.Contracts.AcceptContractAsync(Id);
            IsAccepted = updatedContract.Accepted;
            StatusMessage = "Accepted";
        }
        catch (Exception ex)
        {
            StatusMessage = ex.Message;
        }
        finally
        {
            IsBusy = false;
            AcceptCommand.NotifyCanExecuteChanged();
            FulfillCommand.NotifyCanExecuteChanged();
        }
    }

    private bool CanAccept() => !IsAccepted && !IsFulfilled && !IsBusy;

    [RelayCommand(CanExecute = nameof(CanFulfill))]
    private async Task FulfillAsync()
    {
        IsBusy = true;
        StatusMessage = "Fulfilling...";
        try
        {
            var updatedContract = await _session.Client.Contracts.FulfillContractAsync(Id);
            IsFulfilled = updatedContract.Fulfilled;
            StatusMessage = "Fulfilled";
        }
        catch (Exception ex)
        {
            StatusMessage = ex.Message;
        }
        finally
        {
            IsBusy = false;
            FulfillCommand.NotifyCanExecuteChanged();
        }
    }

    private bool CanFulfill() => IsAccepted && !IsFulfilled && !IsBusy;
}

public class DeliverItemViewModel
{
    private readonly ContractDeliver _deliver;

    public string TradeSymbol => _deliver.TradeSymbol;
    public string DestinationSymbol => _deliver.DestinationSymbol;
    public int UnitsRequired => _deliver.UnitsRequired;
    public int UnitsFulfilled => _deliver.UnitsFulfilled;
    public double ProgressPercent => UnitsRequired > 0 ? (UnitsFulfilled * 100.0 / UnitsRequired) : 0;
    public string ProgressText => $"{UnitsFulfilled:N0} / {UnitsRequired:N0}";

    public DeliverItemViewModel(ContractDeliver deliver)
    {
        _deliver = deliver;
    }
}