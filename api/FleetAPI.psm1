Import-Module (Join-Path $PSScriptRoot "api\SpaceTradersApi.psm1") -Force

function Invoke-ScrapShip {
    param([Parameter(Mandatory=$true)][string]$ShipSymbol)

    return Invoke-PulseApi -Method "POST" -Path "/my/ships/{shipSymbol}/scrap" -PathParams @{ shipSymbol = $ShipSymbol }
}

function Get-MyShips {
    return Invoke-PulseApi -Method "GET" -Path "/my/ships"
}


Export-ModuleMember -Function Invoke-ScrapShip, Get-MyShips