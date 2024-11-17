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
The source site of the code could be found at https://github.com/loompas0/ 
if you are explicitely or implicitely authorized to access to it.
#>

<#This script has been tested on a Windows environment With Zerto 10.5 version #>

# =====================================================================================
# VpgModificationLtr7Years
# Aim: Modify retention settings in a VPG (Yearly retention period).
# Input Parameters : None
# Output Parameters : None
# Files needed:
#    --- connect-secret.ps1 --- Program to connect to the ZVM
#    --- datacenters.json --- File with DC credentials
# =====================================================================================

# Vpg modification ltr 7 Years 

############################################################
# First get Credential and token to be used for connection #
############################################################ 

# use json file (datacenters.json) to connect to all sites 
# Import required modules
. ./connect-secret.ps1
# Now that we have a token because of successful Keycloak authentication, we can proceed with Zerto REST API calls
# Now we have 
#       * The basic address of the zvm          : $zvmApiBase
#       * The token to be used as a Bearer      : $token

#########################################
# Second Retreive VPG identifier        #
######################################### 

#API Call
$request = @{

    Headers     = @{
        "Content-Type"  = "application/json"
        Authorization = "Bearer ${token}"
    }

    StatusCodeVariable = "statusCode"

    Method      = "GET"
    URI = $zvmApiBase + "vpgs/"

    SkipCertificateCheck = $skipCertificateCheck
}

try {
    $result = Invoke-RestMethod @request
}
catch {
    Write-Error "Error making API call to ZVM" -ErrorAction Stop
}

# write  $result
$result | Select-Object VpgIdentifier, VPGName,VMsCount, SourceSite, TargetSite, ActualRPO, IOPS, ThroughputInMB | format-table 


# lets print all VPG To choose the right one if there is more than one 

# Function used in a loop to list all VPG
function Show-VPG-List
{
    
    $textline = “$i : Press ‘$i’ for choosing VPG : *** $VpgName *** ($VpgId).”
   # write Menu
    Write-Host $textline -ForegroundColor Green

}

# Select VPG depending of the answer from the screen

if ($result.Count -eq 1) 
{
    $VpgIdentifier = $result.VpgIdentifier
}
else 
{
    $VpgTitle = "Which VPG do you want to modify"
    Write-Host “== $VpgTitle ==”
    for (($i=0); $i -lt $result.count; $i++)
    {
        $VpgName = $result.VpgName[$i]
        $VpgId = $result.VpgIdentifier[$i]
        Show-VPG-List
    }
    $response = Read-Host “Please make a selection”
    if ($response -gt $result.count-1) 
    {
        Write-Error "Number is out of scope" -ErrorAction Stop
    }
    $VpgIdentifier = $result.VpgIdentifier[$response]
}

# Now we have 
#       * The basic address of the zvm              : $zvmApiBase
#       * The token to be used as a Bearer          : $token
#       * the id of the VPG to be modified          : $VpgIdentifier

############################################################
# Third Lets create a VPG Setting from semected VPG        #
############################################################

# API CALL
$Headers = @{
    "Content-Type"  = "application/json"
    Authorization = "Bearer ${token}"
    Accept = "application/json"
}
$Body = "{`"vpgIdentifier`" :  `"$VpgIdentifier`"}"
$UriApi = $zvmApiBase + "vpgSettings/"

$result = Invoke-RestMethod -Uri $UriApi  -Headers $Headers -Method Post -Body $Body -SkipCertificateCheck
$VpgSettingsIdentifier = $result

# Now we have 
#       * The basic address of the zvm              : $zvmApiBase
#       * The token to be used as a Bearer          : $token
#       * the id of the VPG to be modified          : $VpgIdentifier
#       * the id of the modifications (settings)    : $VpgSettingsIdentifier

#########################################
# Fourth Lets retrieve all VPG Setting  #
#########################################

# API CALL
$Headers = @{
    "Content-Type"  = "application/json"
    Authorization = "Bearer ${token}"
    Accept = "application/json"
}
$UriApi = $zvmApiBase + "vpgSettings/" + $VpgSettingsIdentifier

$result = Invoke-RestMethod -Uri $UriApi  -Headers $Headers -Method Get  -SkipCertificateCheck
$VpgSettings = $result

# Now we have 
#       * The basic address of the zvm              : $zvmApiBase
#       * The token to be used as a Bearer          : $token
#       * the id of the VPG to be modified          : $VpgIdentifier
#       * the id of the modifications (settings)    : $VpgSettingsIdentifier
#       * the full settings of the VPG              : $VpgSettings 

##############################################
# Fith Enter nb year and Change VpgSettings  #
##############################################

#  Read the number of years and put it in Nb Years
#  to be used in  $VpgSettings.LongTermRetention.SchedulerPolicy.Yearly.RetentionDuration    
$NbYearsString = Read-Host "Please enter Number of years : (should be less than 8)"
$NbYears = [int]$NbYearsString

if ($NbYears -gt 8) 
{
    Write-Error "Number of year is out of scope" -ErrorAction Stop
}

# Change the Number of years for LTR retention duration
$VpgSettings.LongTermRetention.SchedulerPolicy.Yearly.RetentionDuration.Count = $NbYears

# Convert the variable $VpgSettings to Json format $VpgSettingsJson
$VpgSettingsJson = $VpgSettings | ConvertTo-Json -Depth 7

# Now we have 
#       * The basic address of the zvm              : $zvmApiBase
#       * The token to be used as a Bearer          : $token
#       * the id of the VPG to be modified          : $VpgIdentifier
#       * the id of the modifications (settings)    : $VpgSettingsIdentifier
#       * the full settings of the VPG              : $VpgSettings modified with correct number of years
#       * The full settings of VPG in Json format   : $VpgSettingsJson modified with correct nb of year

##############################################
# Sixth  Modify Vpg settings in ZVM          #
##############################################

# API CALL
$Headers = @{
    "Content-Type"  = "application/json"
    Authorization = "Bearer ${token}"
    Accept = "application/json"
}
$Body = $VpgSettingsJson 
$UriApi = $zvmApiBase + "vpgSettings/" + $VpgSettingsIdentifier

$result = Invoke-RestMethod -Uri $UriApi  -Headers $Headers  -Body $Body -Method Put  -SkipCertificateCheck

# Now we have 
#       * The basic address of the zvm              : $zvmApiBase
#       * The token to be used as a Bearer          : $token
#       * the id of the VPG to be modified          : $VpgIdentifier
#       * the id of the modifications (settings)    : $VpgSettingsIdentifier
#       * the full settings of the VPG              : $VpgSettings modified with correct number of years
#       * The full settings of VPG in Json format   : $VpgSettingsJson modified with correct nb of year
#       * The seetings modified in ZVM

##############################################
# Seventh  Commit Vpg settings to modify VPG #
##############################################

# API CALL
$Headers = @{
    "Content-Type"  = "application/json"
    Authorization = "Bearer ${token}"
    Accept = "application/json"
}

$UriApi = $zvmApiBase + "vpgSettings/" + $VpgSettingsIdentifier + "/commit"


$result = Invoke-RestMethod -Uri $UriApi  -Headers $Headers  -Method Post  -SkipCertificateCheck

Write-Host "The VPG  $VpgSettingsIdentifier has $NBYears Years of retention"

# *** End of Program ***