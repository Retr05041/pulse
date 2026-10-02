# SpaceTraders API transport.
#
# Synchronous HTTP transport for PowerShell 7+.
#
# The API returns:
# {
#     "data": ...
# }
#
# This module unwraps "data" before returning it.

Set-StrictMode -Version Latest

function Invoke-PulseApi {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [hashtable]$PathParams,

        [ValidateSet("GET", "POST", "PUT", "DELETE", "PATCH")]
        [string]$Method = "GET",

        [hashtable]$Body,

        [Parameter(Mandatory = $true)]
        [string]$AgentToken
    )

    if ([string]::IsNullOrWhiteSpace($AgentToken)) {
        throw "AgentToken is required."
    }

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw "API Path is required."
    }

    # Replace path parameters such as:
    # /my/ships/{shipSymbol}
    if ($null -ne $PathParams) {

        foreach ($key in $PathParams.Keys) {

            $value = [string]$PathParams[$key]

            $Path = $Path.Replace(
                "{$key}",
                [uri]::EscapeDataString($value)
            )
        }
    }

    # SpaceTraders API base URL.
    $apiHost = "https://api.spacetraders.io/v2"

    $fullUrl = $apiHost.TrimEnd('/') + '/' + $Path.TrimStart('/')

    $headers = @{
        Authorization = "Bearer $AgentToken"
        Accept        = "application/json"
    }

    $requestParams = @{
        Uri         = $fullUrl
        Method      = $Method
        Headers     = $headers
        ErrorAction = "Stop"
    }

    if ($null -ne $Body) {

        $requestParams.Body =
            $Body | ConvertTo-Json -Depth 20 -Compress

        $requestParams.ContentType =
            "application/json"
    }

    $response = Invoke-RestMethod @requestParams

    # SpaceTraders normally wraps the useful result in "data".
    if ($null -ne $response.data) {
        return $response.data
    }

    return $response
}

Export-ModuleMember -Function Invoke-PulseApi