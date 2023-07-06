./user-connection-secret.ps1
# Now that we have a token because of successful Keycloak authentication, we can proceed with Zerto REST API calls
# Get vpgidentifier to put it on a variable
$ZertoVpgIdentifier= Read-Host -Prompt 'Input the ZertoVPG Identifier '
# Write-Output  $ZertoVpgIdentifier
# API CALL

$Headers = @{
            "Content-Type"  = "application/json"
            Authorization = "Bearer ${token}"
            Accept = "application/json"
        }
$Body = "{`"vpgIdentifier`" :  `"$ZertoVpgIdentifier`"}"
$UriApi = $zvmApiBase + "vpgSettings/copyVpgSettings/"


$result = Invoke-RestMethod -Uri $UriApi  -Headers $Headers -Method Post -Body $Body -SkipCertificateCheck


# $request = @{

#     Headers     = @{
#         "Content-Type"  = "application/json"
#         Authorization = "Bearer ${token}"
#         Accept = "application/json"
#     }

#     Body        = "{`"vpgIdentifier`" :  `"$ZertoVpgIdentifier`"}"
 
#     StatusCodeVariable = "statusCode"

#     Method      = "POST"
#     URI = $zvmApiBase + "vpgSettings/copyVpgSettings/"

#     SkipCertificateCheck = $skipCertificateCheck
# }
# #  Write-Output $request
# try {
#     $result = Invoke-RestMethod @request
# }
# catch {
#     Write-Error "Error making API call to ZVM" -ErrorAction Stop
# }

write-output $result

