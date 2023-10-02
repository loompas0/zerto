# . ./user-connection-secret.ps1
# use json file to connect to all sites
. ./connect-secret.ps1
# Now that we have a token because of successful Keycloak authentication, we can proceed with Zerto REST API calls

# prepare list of LTR by using API
$requestLTR = @{

    Headers     = @{
        ContentType  = "application/json"
        Authorization = "Bearer ${token}"
    }

    StatusCodeVariable = "statusCode"

    Method      = "GET"
    URI = $zvmApiBase + "ltr/repositories"

    SkipCertificateCheck = $skipCertificateCheck
}

# prepare list of VM by using API
$requestVM = @{

    Headers     = @{
        ContentType  = "application/json"
        Authorization = "Bearer ${token}"
    }

    StatusCodeVariable = "statusCode"

    Method      = "GET"
    URI = $zvmApiBase + "ltr/catalog/vms"

    SkipCertificateCheck = $skipCertificateCheck
}


try {
    $resultLTR = Invoke-RestMethod @requestLTR
}
catch {
    Write-Error "Error making API call to ZVM" -ErrorAction Stop
}



try {
    $resultVM = Invoke-RestMethod @requestVM
}
catch {
    Write-Error "Error making API call to ZVM" -ErrorAction Stop
}


# write-output $result
Write-Host "List of All LTR available" -ForegroundColor Green
$resultLTR | Select-Object repositoryIdentifier, repositoryName, storageType  | format-table 
# lets put all content of $result in variable
Write-Host "List of All VM and VPG available" -ForegroundColor Blue
$VmId = $resultVM.Vms.Vm.Identifier
$VmName= $resultVM.Vms.Vm.Name
$VpgId = $resultVM.Vms.Vpg.Identifier
$VpgName= $resultVM.Vms.Vpg.Name

Write-Host "The Vm Identifier  is : $VmId" -ForegroundColor Yellow
Write-Host "The Vm Name is : $VmName" -ForegroundColor Yellow
Write-Host "The Vpg Identifier  is : $VpgId" -ForegroundColor Yellow
Write-Host "The Vm Name is : $VPGName" -ForegroundColor Yellow

