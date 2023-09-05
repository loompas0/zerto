. ./user-connection-secret.ps1
# Now that we have a token because of successful Keycloak authentication, we can proceed with Zerto REST API calls
# Get vpgidentifier to put it on a variable
$ZertoVpgSettings= Read-Host -Prompt 'Input the Zerto VPGsettings Identifier '
# Write-Output  $ZertoVpgSettings

# Change possible

$ZertoVpgName= Read-Host -Prompt 'Input the Zerto VPG New Name :'
$ZertoRpo= Read-Host -Prompt 'Input the Zerto VPG RPO (in second) :'
$ZertoJournal= Read-Host -Prompt 'Input the Zerto VPG Journal (in hours) :'



# API CALL

$Headers = @{
            "Content-Type"  = "application/json"
            Authorization = "Bearer ${token}"
            Accept = "application/json"
        }
$Body = 
    "{
        `"VpgIdentifier`": null,
        `"VpgSettingsIdentifier`": `"$ZertoVpgSettings`",
        `"Basic`":
        {
            `"Name`": `"$ZertoVpgName`",
            `"RpoInSeconds`": `"$ZertoRpo`",
            `"JournalHistoryInHours`": `"$ZertoJournal`"
        }
    }"
$UriApi = $zvmApiBase + "vpgSettings/" + $ZertoVpgSettings 


$result = Invoke-RestMethod -Uri $UriApi  -Headers $Headers -Method Put -Body $Body -SkipCertificateCheck
Write-Host $result



write-output "Modification ok pour Vpg settings :  $ZertoVpgSettings "
# $result | Select-Object VpgIdentifier, VPGName,VMsCount, SourceSite, TargetSite, ActualRPO, IOPS, ThroughputInMB | format-table 
