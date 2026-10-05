using System.Windows;
using System.Windows.Controls;
using Pulse.ViewModels;

namespace Pulse.Views;

// The only code-behind with logic: it syncs the PasswordBox (which can't data-bind) both ways.
public partial class LoginView : UserControl
{
    public LoginView()
    {
        InitializeComponent();

        // DataContext is assigned AFTER construction, so wait for it to arrive.
        DataContextChanged += (_, e) =>
        {
            if (e.NewValue is LoginViewModel vm)       // pattern matching: type test + cast in one
                vm.PropertyChanged += (_, args) =>
                {
                    // View model -> box (e.g. user picked a saved agent).
                    if (args.PropertyName == nameof(LoginViewModel.Token) && TokenBox.Password != vm.Token)
                        TokenBox.Password = vm.Token;
                };
        };
    }

    // Box -> view model (user typed/pasted).
    private void TokenBox_PasswordChanged(object sender, RoutedEventArgs e)
    {
        if (DataContext is LoginViewModel vm) vm.Token = TokenBox.Password;
    }
}
