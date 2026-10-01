Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

function New-ShipUserControl {
    param (
        [string]$ShipName = "Unknown Ship",
        [int]$ShieldPercent = 100,
        [int]$HullPercent = 100
    )

    # 1. Define XAML layout for a single Ship Card
    [xml]$shipXaml = @"
    <UserControl xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
                 xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
                 Margin="5">
        <Border BorderBrush="#4A5568" BorderThickness="1" CornerRadius="6" Background="#1A202C" Padding="10">
            <StackPanel>
                <!-- Ship Header -->
                <TextBlock x:Name="TxtShipName" Text="Ship Name" Foreground="#E2E8F0" 
                           FontSize="14" FontWeight="Bold" Margin="0,0,0,8" TextAlignment="Center"/>

                <!-- Shield Bar -->
                <TextBlock Text="Shields" Foreground="#A0AEC0" FontSize="10"/>
                <Grid Margin="0,2,0,8">
                    <ProgressBar x:Name="PbShield" Height="14" Foreground="#3182CE" Background="#2D3748" Minimum="0" Maximum="100"/>
                    <TextBlock x:Name="TxtShield" Foreground="White" FontSize="10" 
                               HorizontalAlignment="Center" VerticalAlignment="Center" FontWeight="Bold"/>
                </Grid>

                <!-- Hull Bar -->
                <TextBlock Text="Hull Integrity" Foreground="#A0AEC0" FontSize="10"/>
                <Grid Margin="0,2,0,0">
                    <ProgressBar x:Name="PbHull" Height="14" Foreground="#E53E3E" Background="#2D3748" Minimum="0" Maximum="100"/>
                    <TextBlock x:Name="TxtHull" Foreground="White" FontSize="10" 
                               HorizontalAlignment="Center" VerticalAlignment="Center" FontWeight="Bold"/>
                </Grid>
            </StackPanel>
        </Border>
    </UserControl>
"@

    # 2. Load XAML Node
    $reader = [System.Xml.XmlNodeReader]::new($shipXaml)
    $control = [System.Windows.Markup.XamlReader]::Load($reader)

    # 3. Find named internal WPF controls
    $txtShipName = $control.FindName("TxtShipName")
    $pbShield    = $control.FindName("PbShield")
    $txtShield   = $control.FindName("TxtShield")
    $pbHull      = $control.FindName("PbHull")
    $txtHull     = $control.FindName("TxtHull")

    # Store internal references in the control's Tag property for quick access
    $control.Tag = @{
        TxtShipName = $txtShipName
        PbShield    = $pbShield
        TxtShield   = $txtShield
        PbHull      = $pbHull
        TxtHull     = $txtHull
    }

    # 4. Attach custom method to feed/update data dynamically
    $control | Add-Member -MemberType ScriptMethod -Name "LoadShipData" -Value {
        param([hashtable]$Data)

        if ($Data.Name) { $this.Tag.TxtShipName.Text = $Data.Name }
        if ($null -ne $Data.Shield) { 
            $this.Tag.PbShield.Value = $Data.Shield
            $this.Tag.TxtShield.Text = "$($Data.Shield)%"
        }
        if ($null -ne $Data.Hull) { 
            $this.Tag.PbHull.Value = $Data.Hull
            $this.Tag.TxtHull.Text = "$($Data.Hull)%"
        }
    }

    # Initial data load
    $control.LoadShipData(@{ Name = $ShipName; Shield = $ShieldPercent; Hull = $HullPercent })

    return $control
}