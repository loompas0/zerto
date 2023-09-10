<#
Legal Disclaimer
This script is an example script and is not supported by any means.
The author further disclaim all implied warranties including, 
without limitation, any implied warranties of merchantability 
or of fitness for a particular purpose.
In no event shall  its authors or anyone else involved in 
the creation, production or delivery of the scripts be liable for 
any damages whatsoever 
(including, without limitation, damages for loss of business profits, business interruption, 
loss of business information, or other pecuniary loss) arising out of the use of or the inability 
to use the sample scripts or documentation, 
even if the author  has been advised of the possibility of such damages. 
The entire risk arising out of the use or performance of the sample scripts 
and documentation remains with you.
#>

<#
The Author is Loompas0 who is a pseudo.
The source site of the code couldbe https://github.com/loompas0/ 
if you are explicitely or implicitely authorized to access to it.
#>

# History 
# - 09/10/2023 creation and first tests

# Read file listing all DC datacenters.json
$DCFile = Get-Content -path .\datacenters.json -Raw | ConvertFrom-Json -ErrorAction Stop
# define title of the menu
$Title = "On Which DC Do you want to be connected"
# count number of lines in the array from Json file
$NbDc = $DCFile.DataCenters.Count
# Handle menu in a function
function Show-Menu 
{
    
    $textline = “$i : Press ‘$i’ for the datacenter $DcName ($DcIp).”
   # write Menu
    Write-Host $textline 

}

Write-Host “== $Title ==”

for (($i=0); $i -lt $NbDc; $i++)
    {
        
        $DcName = $DCFile.DataCenters.DCName[$i]
        $DcIp = $DCFile.DataCenters.ServerIp[$i]
        
        Show-Menu 
        
    }

$DC = Read-Host “Please make a selection”
if ($DC -gt $NbDc-1) 
{
    Write-Error "Number is out of scope" -ErrorAction Stop
}

$zvmAddress = $DCFile.DataCenters.ServerIp[$DC]
$keycloakClientID = $DCFile.DataCenters.KeycloakClientID[$DC]
$keycloakClientSecret = $DCFile.DataCenters.KeycloakClientSecret[$DC]

# Write-Host $zvmAddress
# Write-Host $keycloakClientID
# Write-Host $keycloakClientSecret

$skipCertificateCheck = $true       # for self-signed certs, so this flag is passed to Invoke-RestMethod to allow it to proceed.

# Nothing below this line needs to be changed

# Setup API string conventions for later use

$keyCloakApiBase = "https://" + $zvmAddress + "/auth/realms/zerto/protocol/openid-connect/token"
$zvmApiBase = "https://" + $zvmAddress + "/v1/" 

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


