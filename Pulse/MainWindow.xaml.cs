using System.Windows;

namespace Pulse;

// Intentionally empty: all behaviour lives in view models. InitializeComponent() loads the XAML.
public partial class MainWindow : Window
{
    public MainWindow() => InitializeComponent();   // "=>" is an expression-bodied member
}
