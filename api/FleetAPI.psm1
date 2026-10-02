Import-Module (Join-Path $PSScriptRoot "SpaceTradersAPI.psm1") -Force


function Invoke-ScrapShip {

    param(
        [Parameter(Mandatory = $true)]
        [string]$ShipSymbol,

        [Parameter(Mandatory = $true)]
        [string]$AgentToken
    )

    return Invoke-PulseApi `
        -Method "POST" `
        -Path "/my/ships/{shipSymbol}/scrap" `
        -PathParams @{
            shipSymbol = $ShipSymbol
        } `
        -AgentToken $AgentToken
}


function Get-MyShips {

    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentToken
    )

    return Invoke-PulseApi `
        -Method "GET" `
        -Path "/my/ships" `
        -AgentToken $AgentToken
}


Export-ModuleMember `
    -Function Invoke-ScrapShip, Get-MyShips