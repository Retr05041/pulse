Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$componentsPath = Join-Path $PSScriptRoot "Components"
$apiPath        = Join-Path $PSScriptRoot "Api"

Import-Module `
    (Join-Path $componentsPath "LoginComponent.psm1") `
    -Force

Import-Module `
    (Join-Path $componentsPath "ShipComponent.psm1") `
    -Force

Import-Module `
    (Join-Path $apiPath "SpaceTradersAPI.psm1") `
    -Force

Import-Module `
    (Join-Path $apiPath "AgentAPI.psm1") `
    -Force

Import-Module `
    (Join-Path $apiPath "FleetAPI.psm1") `
    -Force


# ---------------------------------------------------------------------------
# Fleet Window
# ---------------------------------------------------------------------------

function New-FleetWindow {

    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentSymbol,

        [Parameter(Mandatory = $true)]
        [string]$AgentToken,

        [Parameter(Mandatory = $true)]
        [object]$Agent
    )


    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="P.U.L.S.E."
        Height="620"
        Width="900"
        MinHeight="500"
        MinWidth="700"
        Background="#0F172A"
        WindowStartupLocation="CenterScreen">

    <Grid Margin="22">

        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>


        <!-- Header -->

        <DockPanel>

            <StackPanel>

                <TextBlock
                    Text="FLEET STATUS"
                    Foreground="#38BDF8"
                    FontSize="12"
                    FontWeight="Bold"/>

                <TextBlock
                    x:Name="AgentTitle"
                    Foreground="#F8FAFC"
                    FontSize="25"
                    FontWeight="SemiBold"
                    Margin="0,4,0,0"/>

            </StackPanel>

            <TextBlock
                x:Name="FleetStatus"
                DockPanel.Dock="Right"
                Foreground="#94A3B8"
                FontSize="12"
                VerticalAlignment="Bottom"/>

        </DockPanel>


        <!-- Fleet -->

        <ScrollViewer
            Grid.Row="1"
            VerticalScrollBarVisibility="Auto"
            Margin="0,18,0,0">

            <UniformGrid
                x:Name="FleetPanel"
                Columns="3"/>

        </ScrollViewer>


        <!-- Footer -->

        <TextBlock
            x:Name="FooterStatus"
            Grid.Row="2"
            Foreground="#64748B"
            FontSize="11"
            Margin="0,12,0,0"/>

    </Grid>

</Window>
"@


    # -----------------------------------------------------------------------
    # Build window
    # -----------------------------------------------------------------------

    $reader = [System.Xml.XmlNodeReader]::new($xaml)
    $window = [System.Windows.Markup.XamlReader]::Load($reader)


    # -----------------------------------------------------------------------
    # Controls
    # -----------------------------------------------------------------------

    $fleetPanel   = $window.FindName("FleetPanel")
    $agentTitle   = $window.FindName("AgentTitle")
    $fleetStatus  = $window.FindName("FleetStatus")
    $footerStatus = $window.FindName("FooterStatus")


    $agentTitle.Text = $AgentSymbol
    $fleetStatus.Text = "Loading fleet..."
    $footerStatus.Text = ""


    # -----------------------------------------------------------------------
    # Load ships
    # -----------------------------------------------------------------------

    try {

        $ships = @(Get-MyShips -AgentToken $AgentToken)


        if ($null -eq $ships -or $ships.Count -eq 0) {

            $fleetStatus.Text = "0 ships"
            $footerStatus.Text = "SpaceTraders returned no ships."

            return $window
        }


        $fleetPanel.Children.Clear()


        foreach ($ship in $ships) {

            $shipControl = New-ShipUserControl -Ship $ship

            [void]$fleetPanel.Children.Add($shipControl)
        }


        $plural = if ($ships.Count -eq 1) {
            ""
        }
        else {
            "s"
        }


        $fleetStatus.Text =
            "{0} ship{1}" -f $ships.Count, $plural

        $footerStatus.Text =
            "Fleet data loaded successfully."

    }
    catch {

        $fleetStatus.Text = "Fleet unavailable"

        $footerStatus.Text =
            $_.Exception.Message
    }


    return $window
}


# ---------------------------------------------------------------------------
# Login -> Fleet
# ---------------------------------------------------------------------------

$loginWindow = New-AgentLoginWindow -OnLoggedIn {

    param(
        $AgentSymbol,
        $AgentToken,
        $Agent
    )


    try {

        # Create the fleet window using the authenticated session.
        $fleetWindow = New-FleetWindow `
            -AgentSymbol $AgentSymbol `
            -AgentToken $AgentToken `
            -Agent $Agent


        # Show the fleet.
        $fleetWindow.Show()

    }
    catch {

        [System.Windows.MessageBox]::Show(
            $_.Exception.Message,
            "P.U.L.S.E. Error",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        )
    }

}


# ---------------------------------------------------------------------------
# Start application
# ---------------------------------------------------------------------------

$loginWindow.ShowDialog() | Out-Null