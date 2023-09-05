<#
Legal Disclaimer
This script is an example script and is not supported under any Zerto support program or service. The author and Zerto further disclaim all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose.

In no event shall Zerto, its authors or anyone else involved in the creation, production or delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or the inability to use the sample scripts or documentation, even if the author or Zerto has been advised of the possibility of such damages. The entire risk arising out of the use or performance of the sample scripts and documentation remains with you.
#>

# Notes:
# - requires ZVM Linux Appliance 9.5U1 or higher, developed and tested on 9.5U3

#Choose server to be connectted and affect secret to it 
$DC1 ='10.13.1.190'
$DC2 ='10.13.1.191'
function Show-Menu
{
    param
    (
        [string]$Title = ‘On Which DC Do you want to be connected’
    )
    # $DC1 ='10.13.1.190'
    # $DC2 ='10.13.1.191'
   # write Menu
    Write-Host “== $Title ==”
    Write-Host “1: Press ‘1’ for DC1 ($DC1).”
    Write-Host “2: Press ‘2’ for DC2 ($DC2).”
}

Show-Menu 

$DC = Read-Host “Please make a selection”

switch ($DC)
{
    ‘1’
    {
        $zvmAddress = $DC1
        $keycloakClientID = "api-script"
        $keycloakClientSecret = "CpFGp28bstjzOclQdR6RUBpZ23m7p8Rm"
    }
    ‘2’
    {
        $zvmAddress = $DC2
        $keycloakClientID = "api-script"
        $keycloakClientSecret = "4Mf81PXuGyiWhtf0QBPIxs7hambA8DVK"
    }
}
$skipCertificateCheck = $true       # for self-signed certs, so this flag is passed to Invoke-RestMethod to allow it to proceed.

# Nothing below this line needs to be changed

# Setup API string conventions for later use

$keyCloakApiBase = "https://" + $zvmAddress + "/auth/realms/zerto/protocol/openid-connect/token"
# $zvmApiBase = "https://" + $zvmAddress + "/v1/" 

# Connect to Keycloak with secret and get token
# Note: using Splat concept to neatly layout the arguments for Headers, Body, Method, and URI before making the call
# Splat is defined like a variable ($ prefix) but referenced in special way (@ prefix) which maps parameter/value for the function as key value pairs

$request = @{

    Headers     = @{
        ContentType  = "application/x-www-form-urlencoded"
    }

    Body        = @{
        client_id = $keycloakClientID
        client_secret = $keycloakClientSecret
        grant_type = "client_credentials"
    }
 
    StatusCodeVariable = "statusCode"

    Method      = "POST"
    URI = $keyCloakApiBase

    SkipCertificateCheck = $skipCertificateCheck
}

try {
    $result = Invoke-RestMethod @request
}
catch {
    Write-Error "Error connecting to Keycloak" -ErrorAction Stop
}
$token = $result.access_token

