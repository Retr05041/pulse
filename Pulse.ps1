Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# Resolve path relative to this script
$componentsPath = Join-Path $PSScriptRoot "components"

# Option A: Import a specific module
Import-Module (Join-Path $componentsPath "ShipComponent.psm1") -Force

# Option B: Dot-source all modules in the components folder automatically
# Get-ChildItem -Path $componentsPath -Filter "*.psm1" | ForEach-Object {
#     Import-Module $_.FullName -Force
# }

# Load all API domain modules at startup
# Get-ChildItem -Path (Join-Path $PSScriptRoot "api") -Filter "*.psm1" | ForEach-Object {
#     Import-Module $_.FullName -Force
# }

# Create the Main Window Layout
[xml]$mainWindowXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="P.U.L.S.E." Height="320" Width="550" Background="#3b3e44">
    <Grid Margin="15">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <TextBlock Text="FLEET STATUS MONITOR" Foreground="#38BDF8" FontSize="16" 
                   FontWeight="Bold" Margin="0,0,0,10"/>

        <!-- Container for our dynamically added ship components -->
        <UniformGrid x:Name="FleetPanel" Grid.Row="1" Columns="3"/>
    </Grid>
</Window>
"@

# Load Main Window
$mainReader = [System.Xml.XmlNodeReader]::new($mainWindowXaml)
$window = [System.Windows.Markup.XamlReader]::Load($mainReader)
$fleetPanel = $window.FindName("FleetPanel")

# --- FEED DATA TO REUSABLE COMPONENTS ---

# Ship 1: Standard Instance
$ship1 = New-ShipUserControl -ShipName "USS Enterprise" -ShieldPercent 100 -HullPercent 95
$fleetPanel.Children.Add($ship1) | Out-Null

# Ship 2: Damaged Instance
$ship2 = New-ShipUserControl -ShipName "Rocinante" -ShieldPercent 15 -HullPercent 40
$fleetPanel.Children.Add($ship2) | Out-Null

# Ship 3: Instance loaded dynamically using .LoadShipData()
$ship3 = New-ShipUserControl
$shipData = @{
    Name   = "Millennium Falcon"
    Shield = 85
    Hull   = 70
}
$ship3.LoadShipData($shipData)
$fleetPanel.Children.Add($ship3) | Out-Null

# Show the Application
$window.ShowDialog() | Out-Null