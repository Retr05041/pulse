Import-Module (Join-Path $PSScriptRoot "api\SpaceTradersApi.psm1") -Force

function Get-Agent {
    return Invoke-PulseApi -Method "GET" -Path "/my/agent"
}

Export-ModuleMember -Function Get-Agent