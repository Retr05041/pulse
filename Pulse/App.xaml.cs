using System.Windows;
using Pulse.Services;
using Pulse.ViewModels;

namespace Pulse;   // file-scoped namespace: applies to the whole file, saves an indent level

public partial class App : Application   // "partial": other half is generated from App.xaml
{
    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);

        // Composition root: the ONE place long-lived services are created and wired together.
        // (If this grows, swap for Microsoft.Extensions.DependencyInjection.)
        var pulse = new PulseService();
        var store = new CredentialStore();

        new MainWindow { DataContext = new ShellViewModel(pulse, store) }.Show();
    }
}
