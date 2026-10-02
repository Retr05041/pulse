Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

Import-Module (Join-Path $PSScriptRoot "..\Api\SpaceTradersAPI.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "..\Api\AgentAPI.psm1") -Force


function New-AgentLoginWindow {

    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$OnLoggedIn
    )


    # -----------------------------------------------------------------------
    # Window
    # -----------------------------------------------------------------------

    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="P.U.L.S.E. - Agent Login"
        Height="500"
        Width="650"
        WindowStartupLocation="CenterScreen"
        Background="#0F172A">

    <Grid Margin="24">

        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>


        <!-- Header -->

        <StackPanel>

            <TextBlock
                Text="P.U.L.S.E."
                Foreground="#38BDF8"
                FontSize="12"
                FontWeight="Bold"/>

            <TextBlock
                Text="Agent Login"
                Foreground="#F8FAFC"
                FontSize="28"
                FontWeight="SemiBold"
                Margin="0,4,0,2"/>

            <TextBlock
                Text="Enter your SpaceTraders agent token."
                Foreground="#94A3B8"
                FontSize="12"/>

        </StackPanel>


        <!-- Token -->

        <Border
            Grid.Row="1"
            Margin="0,20,0,16"
            Background="#172033"
            BorderBrush="#334155"
            BorderThickness="1"
            CornerRadius="8"
            Padding="12">

            <Grid>

                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <PasswordBox
                    x:Name="TokenBox"
                    Height="36"
                    Padding="9,5"
                    Background="#0F172A"
                    Foreground="#E2E8F0"
                    BorderBrush="#475569"
                    ToolTip="SpaceTraders agent token"/>

                <Button
                    x:Name="LoginButton"
                    Grid.Column="1"
                    Content="Login"
                    Margin="10,0,0,0"
                    Padding="22,7"
                    Background="#0EA5E9"
                    Foreground="White"
                    BorderThickness="0"
                    FontWeight="SemiBold"/>

            </Grid>

        </Border>


        <!-- Agent -->

        <Grid Grid.Row="2">

            <TextBlock
                x:Name="EmptyText"
                Text="Enter a token to load your agent."
                Foreground="#64748B"
                FontSize="14"
                HorizontalAlignment="Center"
                VerticalAlignment="Center"/>

            <Border
                x:Name="AgentCard"
                Visibility="Collapsed"
                Background="#172033"
                BorderBrush="#334155"
                BorderThickness="1"
                CornerRadius="10"
                Padding="24"
                Margin="40">

                <StackPanel>

                    <TextBlock
                        x:Name="AgentSymbol"
                        Foreground="#F8FAFC"
                        FontSize="24"
                        FontWeight="SemiBold"
                        HorizontalAlignment="Center"/>

                    <TextBlock
                        x:Name="AgentFaction"
                        Foreground="#38BDF8"
                        FontSize="13"
                        Margin="0,8,0,0"
                        HorizontalAlignment="Center"/>

                    <TextBlock
                        x:Name="AgentCredits"
                        Foreground="#94A3B8"
                        FontSize="13"
                        Margin="0,12,0,0"
                        HorizontalAlignment="Center"/>

                    <Button
                        x:Name="ContinueButton"
                        Content="Continue"
                        Margin="0,20,0,0"
                        Padding="20,8"
                        Background="#0EA5E9"
                        Foreground="White"
                        BorderThickness="0"
                        FontWeight="SemiBold"
                        HorizontalAlignment="Center"/>

                </StackPanel>

            </Border>

        </Grid>


        <!-- Status -->

        <TextBlock
            x:Name="StatusText"
            Grid.Row="3"
            Margin="0,12,0,0"
            Foreground="#94A3B8"
            FontSize="12"/>

    </Grid>

</Window>
"@


    # -----------------------------------------------------------------------
    # Build WPF window
    # -----------------------------------------------------------------------

    $reader = [System.Xml.XmlNodeReader]::new($xaml)

    $window = [System.Windows.Markup.XamlReader]::Load($reader)


    # -----------------------------------------------------------------------
    # Controls
    # -----------------------------------------------------------------------

    $tokenBox       = $window.FindName("TokenBox")
    $loginButton    = $window.FindName("LoginButton")
    $continueButton = $window.FindName("ContinueButton")

    $emptyText      = $window.FindName("EmptyText")
    $agentCard      = $window.FindName("AgentCard")

    $agentSymbol    = $window.FindName("AgentSymbol")
    $agentFaction   = $window.FindName("AgentFaction")
    $agentCredits   = $window.FindName("AgentCredits")

    $statusText     = $window.FindName("StatusText")


    # -----------------------------------------------------------------------
    # Shared authenticated session
    #
    # IMPORTANT:
    # This is a single shared object.
    #
    # Both event handlers capture this same hashtable rather than separate
    # copies of $currentAgent / $currentToken.
    # -----------------------------------------------------------------------

    $session = @{
        Agent = $null
        Token = $null
    }


    # -----------------------------------------------------------------------
    # Login
    # -----------------------------------------------------------------------

    $loginButton.Add_Click({

        $token = $tokenBox.Password

        if ([string]::IsNullOrWhiteSpace($token)) {

            $statusText.Text =
                "Please enter an agent token."

            $statusText.Foreground =
                [System.Windows.Media.Brushes]::IndianRed

            return
        }


        $loginButton.IsEnabled = $false

        $statusText.Text =
            "Connecting to SpaceTraders..."

        $statusText.Foreground =
            [System.Windows.Media.Brushes]::SlateGray


        try {

            # Synchronous API call.
            $agent = Get-Agent -AgentToken $token


            if ($null -eq $agent) {
                throw "SpaceTraders returned no agent."
            }


            $symbol = [string]$agent.symbol


            if ([string]::IsNullOrWhiteSpace($symbol)) {
                throw "SpaceTraders returned no agent symbol."
            }


            # ---------------------------------------------------------------
            # Store session in the shared object.
            # ---------------------------------------------------------------

            $session.Agent = $agent
            $session.Token = $token


            # ---------------------------------------------------------------
            # Display agent.
            # ---------------------------------------------------------------

            $agentSymbol.Text = $symbol


            if ($agent.startingFaction) {

                $agentFaction.Text =
                    [string]$agent.startingFaction

            }
            else {

                $agentFaction.Text =
                    "Unknown faction"

            }


            $agentCredits.Text =
                "{0:N0} credits" -f [long]$agent.credits


            $emptyText.Visibility =
                [System.Windows.Visibility]::Collapsed

            $agentCard.Visibility =
                [System.Windows.Visibility]::Visible


            $tokenBox.IsEnabled = $false

            $loginButton.IsEnabled = $false

            $continueButton.IsEnabled = $true


            $statusText.Text =
                "Agent connected successfully."

            $statusText.Foreground =
                [System.Windows.Media.Brushes]::LightGreen

        }
        catch {

            $loginButton.IsEnabled = $true

            $statusText.Text =
                $_.Exception.Message

            $statusText.Foreground =
                [System.Windows.Media.Brushes]::IndianRed
        }

    }.GetNewClosure())


    # -----------------------------------------------------------------------
    # Enter key
    # -----------------------------------------------------------------------

    $tokenBox.Add_KeyDown({

        param(
            $sender,
            $e
        )


        if ($e.Key -eq [System.Windows.Input.Key]::Enter) {

            $loginButton.RaiseEvent(
                [System.Windows.RoutedEventArgs]::new(
                    [System.Windows.Controls.Button]::ClickEvent
                )
            )

        }

    }.GetNewClosure())


    # -----------------------------------------------------------------------
    # Continue
    # -----------------------------------------------------------------------

    $continueButton.Add_Click({

        # Make sure login completed.
        if ($null -eq $session.Agent) {

            $statusText.Text =
                "No authenticated agent."

            $statusText.Foreground =
                [System.Windows.Media.Brushes]::IndianRed

            return
        }


        try {

            # Pass the authenticated session to Pulse.ps1.
            & $OnLoggedIn `
                ([string]$session.Agent.symbol) `
                $session.Token `
                $session.Agent


            # Close the login dialog after Pulse successfully receives
            # the authenticated session.
            $window.DialogResult = $true
            $window.Close()

        }
        catch {

            $statusText.Text =
                $_.Exception.Message

            $statusText.Foreground =
                [System.Windows.Media.Brushes]::IndianRed
        }

    }.GetNewClosure())


    # -----------------------------------------------------------------------
    # Return window
    # -----------------------------------------------------------------------

    return $window
}