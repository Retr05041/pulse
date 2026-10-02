# SpaceTraders Agent API

Import-Module `
    (Join-Path $PSScriptRoot "SpaceTradersAPI.psm1") `
    -Force

function Get-Agent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentToken
    )

    if ([string]::IsNullOrWhiteSpace($AgentToken)) {
        throw "AgentToken is required."
    }

    # Invoke-PulseApi returns Task[object].
    return Invoke-PulseApi `
        -Method "GET" `
        -Path "/my/agent" `
        -AgentToken $AgentToken
}

Export-ModuleMember -Function Get-Agent