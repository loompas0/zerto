. ./user-connection-secret.ps1
# Now that we have a token because of successful Keycloak authentication, we can proceed with Zerto REST API calls

$request = @{

    Headers     = @{
        ContentType  = "application/json"
        Authorization = "Bearer ${token}"
    }

    StatusCodeVariable = "statusCode"

    Method      = "GET"
    URI = $zvmApiBase + "vms/"

    SkipCertificateCheck = $skipCertificateCheck
}

try {
    $result = Invoke-RestMethod @request
}
catch {
    Write-Error "Error making API call to ZVM" -ErrorAction Stop
}

# write-output $result
$result | Select-Object VpgIdentifier, VPGName, VmIdentifier, vmName, SourceSite, TargetSite, ActualRPO | format-table 
