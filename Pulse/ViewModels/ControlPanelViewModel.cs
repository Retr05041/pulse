using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Pulse.Services;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Pulse.ViewModels;

public partial class ControlPanelViewModel: ObservableObject
{
    private readonly Session _session;
    private readonly PulseService _pulse;
    private readonly Action _onLogout;
    private readonly Action _onOpenFleet;

    public string AgentSymbol => _session.Agent.Symbol;
    public string CreditsText => $"{_session.Agent.Credits:N0} credits";   // TODO: refresh periodically

    [ObservableProperty] private string _status = "";

    public ControlPanelViewModel(Session session, PulseService pulse, Action onLogout, Action onOpenFleet)
    {
        _session = session; // Session
        _pulse = pulse; // Pulse service handed from ShellView
        _onLogout = onLogout; // What happens on logout
        _onOpenFleet = onOpenFleet; // When "Open Fleet" is selected
    }

    [RelayCommand]
    private void Logout() => _onLogout();

    [RelayCommand]
    private void OpenFleet() => _onOpenFleet();
}
