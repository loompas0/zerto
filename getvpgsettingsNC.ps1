# . ./user-connection-secret.ps1
# use json file to connect to all sites
. ./connect-secret.ps1
# Now that we have a token because of successful Keycloak authentication, we can proceed with Zerto REST API calls

$request = @{

    Headers     = @{
        "Content-Type"  = "application/json"
        Authorization = "Bearer ${token}"
    }

    StatusCodeVariable = "statusCode"

    Method      = "GET"
    URI = $zvmApiBase + "vpgsettings/"

    SkipCertificateCheck = $skipCertificateCheck
}

try {
    $result = Invoke-RestMethod @request
}
catch {
    Write-Error "Error making API call to ZVM" -ErrorAction Stop
}


# write-output $result
# Write-Output $result.Basic.name
# Write-Output $result.VpgSettingsIdentifier $result.Basic.name  | format-table
 $result | Select-Object VpgIdentifier, Vms, VpgSettingsIdentifier, Basic | format-table 
