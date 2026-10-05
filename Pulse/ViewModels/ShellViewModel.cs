using CommunityToolkit.Mvvm.ComponentModel;
using Pulse.Services;

namespace Pulse.ViewModels;

/// <summary>
/// Owns "which screen is showing". Navigating = assigning a new view model to CurrentView;
/// the DataTemplates in App.xaml turn it into the right view. One window for the whole app.
/// </summary>
public partial class ShellViewModel : ObservableObject
{
    private readonly PulseService _pulse;
    private readonly CredentialStore _store;

    // [ObservableProperty] generates a public property "CurrentView" (from the _currentView field)
    // that raises PropertyChanged, which is what makes the UI update.
    [ObservableProperty] private object? _currentView;

    public ShellViewModel(PulseService pulse, CredentialStore store)
    {
        _pulse = pulse;
        _store = store;
        ShowLogin();
    }

    private void ShowLogin() =>
        Navigate(new LoginViewModel(_store, session =>
            Navigate(new FleetViewModel(session, _pulse, onLogout: ShowLogin))));

    private void Navigate(object viewModel)
    {
        // Dispose the screen we are leaving (unsubscribes from ticks, closes the HTTP client).
        (CurrentView as IDisposable)?.Dispose();
        CurrentView = viewModel;
    }
}
