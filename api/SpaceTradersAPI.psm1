function Save-AgentToken {
    param([string]$Token)
    
    # Store securely in Windows Credential Manager
    $vault = [Windows.Security.Credentials.PasswordVault]::new()
    $credential = [Windows.Security.Credentials.PasswordCredential]::new("PulseApp", "AgentToken", $Token)
    $vault.Add($credential)
    Write-Host "Agent token securely saved to Windows Credential Manager." -ForegroundColor Green
}

function Get-AgentToken {
    try {
        $vault = [Windows.Security.Credentials.PasswordVault]::new()
        $credential = $vault.Retrieve("PulseApp", "AgentToken")
        $credential.RetrievePassword()
        return $credential.Password
    } catch {
        return $null
    }
}

# Centralized Host Configuration
$script:ApiHost = "https://api.spacetraders.io/v2"

function Invoke-PulseApi {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,             # e.g., "/my/ships/{shipSymbol}/scrap"
        
        [hashtable]$PathParams,    # e.g., @{ shipSymbol = "SHIP-01" }
        
        [ValidateSet("GET", "POST", "PUT", "DELETE", "PATCH")]
        [string]$Method = "GET",
        
        [hashtable]$Body            # Payload for POST/PUT
    )

    # 1. Retrieve the secure token
    $token = Get-AgentToken
    if ([string]::IsNullOrWhiteSpace($token)) {
        throw "No Agent Token found. Please call Save-AgentToken -Token 'YOUR_SECRET' first."
    }

    # 2. Substitute Path Parameters (e.g., replaces {shipSymbol} with actual value)
    if ($PathParams) {
        foreach ($key in $PathParams.Keys) {
            $Path = $Path -replace "\{$key\}", [uri]::EscapeDataString($PathParams[$key])
        }
    }

    # 3. Construct Full URL and Headers
    $fullUrl = "$($script:ApiHost.TrimEnd('/'))/$($Path.TrimStart('/'))"
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Accept"        = "application/json"
    }

    # 4. Prepare parameters for Invoke-RestMethod
    $requestArgs = @{
        Uri         = $fullUrl
        Method      = $Method
        Headers     = $headers
        ContentType = "application/json"
    }

    if ($Body) {
        $requestArgs.Body = ($Body | ConvertTo-Json -Depth 5 -Compress)
    }

    # 5. Execute API Call with Clean Error Handling
    try {
        $response = Invoke-RestMethod @requestArgs
        return $response
    }
    catch {
        # Catch API HTTP errors and extract the actual server response message
        if ($_.Exception.Response) {
            $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
            $errBody = $reader.ReadToEnd()
            Write-Error "API Error [$($_.Exception.Response.StatusCode)]: $errBody"
        } else {
            Write-Error $_.Exception.Message
        }
        return $null
    }
}