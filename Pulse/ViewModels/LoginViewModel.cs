using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Pulse.Api;
using Pulse.Services;

namespace Pulse.ViewModels;

public partial class LoginViewModel : ObservableObject
{
    private readonly CredentialStore _store;
    private readonly Action<Session> _onLoggedIn;      // callback into the shell: "we're in, go to the control panel"

    // ObservableCollection notifies the UI when items are added/removed (a plain List doesn't).
    public ObservableCollection<string> SavedAgents { get; }

    // These generate Token, SelectedAgent, RememberToken, Status, IsBusy properties.
    // [NotifyCanExecuteChangedFor] re-evaluates the Connect button's enabled state when they change.
    [ObservableProperty, NotifyCanExecuteChangedFor(nameof(ConnectCommand))] private string _token = "";
    [ObservableProperty, NotifyCanExecuteChangedFor(nameof(RemoveTokenCommand))] private string? _selectedAgent;
    [ObservableProperty] private bool _rememberToken = true;
    [ObservableProperty] private string _status = "Pick a saved agent or paste a token.";
    [ObservableProperty, NotifyCanExecuteChangedFor(nameof(ConnectCommand))] private bool _isBusy;

    public LoginViewModel(CredentialStore store, Action<Session> onLoggedIn)
    {
        _store = store;
        _onLoggedIn = onLoggedIn;
        SavedAgents = new ObservableCollection<string>(store.GetSymbols());
    }

    // The toolkit calls "On<Property>Changed" partial methods if you define them.
    partial void OnSelectedAgentChanged(string? value)
    {
        if (value is not null) Token = _store.GetToken(value) ?? "";
    }

    private bool CanConnect() => !IsBusy && !string.IsNullOrWhiteSpace(Token);

    private bool CanRemoveToken() => !IsBusy && !string.IsNullOrWhiteSpace(SelectedAgent);

    // [RelayCommand] generates "ConnectCommand" (ICommand) for the button to bind to.
    // "async Task" = the UI thread is NOT blocked while awaiting; the window stays responsive.
    [RelayCommand(CanExecute = nameof(CanConnect))]
    private async Task ConnectAsync()
    {
        IsBusy = true;
        Status = "Connecting to SpaceTraders...";
        var token = Token.Trim();
        var client = new SpaceTradersClient(token);
        try
        {
            var agent = await client.Agents.GetAgentAsync();
            if (RememberToken) _store.Save(agent.Symbol, token);
            _onLoggedIn(new Session(client, agent));   // ownership of the client passes to the control panel screen
        }
        catch (Exception ex)
        {
            client.Dispose();                          // login failed: nobody else will clean this up
            Status = ex.Message;
        }
        finally { IsBusy = false; }                    // always runs, success or failure
    }

    [RelayCommand(CanExecute = nameof(CanRemoveToken))]
    private void RemoveToken()
    {
        if (string.IsNullOrWhiteSpace(SelectedAgent)) return;

        var agentToRemove = SelectedAgent;

        // Remove from file storage & dropdown
        _store.Remove(agentToRemove);
        SavedAgents.Remove(agentToRemove);

        // Reset inputs
        SelectedAgent = null;
        Token = "";
        Status = $"Token for '{agentToRemove}' removed.";
    }
}
