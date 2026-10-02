Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

function New-ShipUserControl {
    param([object]$Ship)

    [xml]$shipXaml = @"
<UserControl xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             Margin="6">
    <Border BorderBrush="#334155" BorderThickness="1" CornerRadius="10"
            Background="#172033" Padding="14">
        <StackPanel>
            <DockPanel Margin="0,0,0,10">
                <TextBlock x:Name="TxtShipSymbol" Foreground="#F8FAFC"
                           FontSize="16" FontWeight="Bold"/>
                <Border DockPanel.Dock="Right" Background="#0F766E"
                        CornerRadius="10" Padding="8,3" Margin="8,0,0,0">
                    <TextBlock x:Name="TxtStatus" Foreground="White"
                               FontSize="9" FontWeight="Bold"/>
                </Border>
            </DockPanel>

            <TextBlock Text="LOCATION" Foreground="#64748B" FontSize="9"
                       FontWeight="Bold"/>
            <TextBlock x:Name="TxtLocation" Foreground="#CBD5E1"
                       FontSize="11" Margin="0,2,0,10"/>

            <TextBlock Text="FUEL" Foreground="#64748B" FontSize="9"
                       FontWeight="Bold"/>
            <Grid Margin="0,2,0,8">
                <ProgressBar x:Name="PbFuel" Height="13" Minimum="0"
                             Maximum="100" Foreground="#38BDF8"
                             Background="#0F172A"/>
                <TextBlock x:Name="TxtFuel" Foreground="White"
                           FontSize="9" HorizontalAlignment="Center"
                           VerticalAlignment="Center" FontWeight="Bold"/>
            </Grid>

            <TextBlock Text="CARGO" Foreground="#64748B" FontSize="9"
                       FontWeight="Bold"/>
            <Grid Margin="0,2,0,0">
                <ProgressBar x:Name="PbCargo" Height="13" Minimum="0"
                             Maximum="100" Foreground="#A78BFA"
                             Background="#0F172A"/>
                <TextBlock x:Name="TxtCargo" Foreground="White"
                           FontSize="9" HorizontalAlignment="Center"
                           VerticalAlignment="Center" FontWeight="Bold"/>
            </Grid>
        </StackPanel>
    </Border>
</UserControl>
"@

    $reader = [System.Xml.XmlNodeReader]::new($shipXaml)
    $control = [System.Windows.Markup.XamlReader]::Load($reader)

    $control.Tag = @{
        TxtShipSymbol = $control.FindName("TxtShipSymbol")
        TxtStatus     = $control.FindName("TxtStatus")
        TxtLocation   = $control.FindName("TxtLocation")
        PbFuel        = $control.FindName("PbFuel")
        TxtFuel       = $control.FindName("TxtFuel")
        PbCargo       = $control.FindName("PbCargo")
        TxtCargo      = $control.FindName("TxtCargo")
    }

    $control | Add-Member -MemberType ScriptMethod -Name "LoadShipData" -Value {
        param([object]$Data)

        $symbol = [string]$Data.symbol
        if ([string]::IsNullOrWhiteSpace($symbol)) {
            $symbol = [string]$Data.Name
        }
        $this.Tag.TxtShipSymbol.Text = if ($symbol) { $symbol } else { "Unknown ship" }

        $status = [string]$Data.nav.status
        $this.Tag.TxtStatus.Text = if ($status) { $status } else { "UNKNOWN" }

        $waypoint = [string]$Data.nav.waypointSymbol
        $system = [string]$Data.nav.systemSymbol
        $location = if ($waypoint) { $waypoint } elseif ($system) { $system } else { "Unknown location" }
        $this.Tag.TxtLocation.Text = $location

        $fuelCurrent = 0
        $fuelCapacity = 0
        if ($null -ne $Data.fuel) {
            $fuelCurrent = [double]$Data.fuel.current
            $fuelCapacity = [double]$Data.fuel.capacity
        }
        $fuelPercent = if ($fuelCapacity -gt 0) {
            [math]::Round(($fuelCurrent / $fuelCapacity) * 100, 0)
        } else { 0 }
        $this.Tag.PbFuel.Value = [math]::Max(0, [math]::Min(100, $fuelPercent))
        $this.Tag.TxtFuel.Text = if ($fuelCapacity -gt 0) {
            "{0:N0} / {1:N0}" -f $fuelCurrent, $fuelCapacity
        } else { "No fuel data" }

        $cargoUnits = 0
        $cargoCapacity = 0
        if ($null -ne $Data.cargo) {
            $cargoUnits = [double]$Data.cargo.units
            $cargoCapacity = [double]$Data.cargo.capacity
        }
        $cargoPercent = if ($cargoCapacity -gt 0) {
            [math]::Round(($cargoUnits / $cargoCapacity) * 100, 0)
        } else { 0 }
        $this.Tag.PbCargo.Value = [math]::Max(0, [math]::Min(100, $cargoPercent))
        $this.Tag.TxtCargo.Text = if ($cargoCapacity -gt 0) {
            "{0:N0} / {1:N0} units" -f $cargoUnits, $cargoCapacity
        } else { "No cargo data" }
    }

    if ($null -ne $Ship) {
        $control.LoadShipData($Ship)
    }

    return $control
}

Export-ModuleMember -Function New-ShipUserControl
