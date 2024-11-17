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

# Import required modules
. ./connect-secret.ps1

# =====================================================================
# Functions
# =====================================================================

# API Call Function
function Invoke-ApiCall {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Uri,
        
        [Parameter(Mandatory=$true)]
        [string]$Method,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Headers = @{},
        
        [Parameter(Mandatory=$false)]
        [string]$Body = ""
    )
    try {
        $response = Invoke-RestMethod -Uri $Uri -Headers $Headers -Method $Method -Body $Body -SkipCertificateCheck
        return $response
    } catch {
        Write-Error "Error making API call to ZVM: $Uri" -ErrorAction Stop
    }
}

# Function to list and choose a VPG
function Select-VPG {
    param ([array]$vpgList)

    if ($vpgList.Count -eq 1) {
        return $vpgList[0].VpgIdentifier
    }

    Write-Host "== Choose a VPG to modify =="

    $vpgList | ForEach-Object {
        $i = $_.Index
        Write-Host "$i : Press '$i' to choose VPG: *** $_.VpgName *** ($_.VpgIdentifier)" -ForegroundColor Green
    }

    $response = Read-Host "Please make a selection"
    if ($response -lt 0 -or $response -ge $vpgList.Count) {
        Write-Error "Selection out of range" -ErrorAction Stop
    }
    return $vpgList[$response].VpgIdentifier
}

# =====================================================================
# Main Script Execution
# =====================================================================

# Step 1: Retrieve API credentials and token from connect-secret.ps1
# (Already included via . ./connect-secret.ps1)

# Now we have the following variables
#       * The basic address of the zvm          : $zvmApiBase
#       * The token to be used as a Bearer      : $token

# Step 2: Retrieve VPG identifiers

$Headers = @{
    "Content-Type" = "application/json"
    "Authorization" = "Bearer $token"
}

$vpgList = Invoke-ApiCall -Uri "$zvmApiBase/vpgs/" -Method "GET" -Headers $Headers

# Now we have 
#       * The basic address of the zvm              : $zvmApiBase
#       * The token to be used as a Bearer          : $token
#       * All Vpg present in the zvm                : $VpgList

# Step 3: Choose a VPG
$VpgIdentifier = Select-VPG -vpgList $vpgList

# Now we have 
#       * The basic address of the zvm              : $zvmApiBase
#       * The token to be used as a Bearer          : $token
#       * All Vpg present in the zvm                : $VpgList
#       * the id of the VPG to be modified          : $VpgIdentifier

# Step 4: Create a VPG setting to modify
$Body = "{`"vpgIdentifier`" :  `"$VpgIdentifier`"}"
$VpgSettingsIdentifier = Invoke-ApiCall -Uri "$zvmApiBase/vpgSettings/" -Method "POST" -Headers $Headers -Body $Body

# Now we have 
#       * The basic address of the zvm              : $zvmApiBase
#       * The token to be used as a Bearer          : $token
#       * All Vpg present in the zvm                : $VpgList
#       * the id of the VPG to be modified          : $VpgIdentifier
#       * the id of the modifications (settings)    : $VpgSettingsIdentifier

# Step 5: Retrieve VPG settings
$VpgSettings = Invoke-ApiCall -Uri "$zvmApiBase/vpgSettings/$VpgSettingsIdentifier" -Method "GET" -Headers $Headers

# Now we have 
#       * The basic address of the zvm              : $zvmApiBase
#       * The token to be used as a Bearer          : $token
#       * All Vpg present in the zvm                : $VpgList
#       * the id of the VPG to be modified          : $VpgIdentifier
#       * the id of the modifications (settings)    : $VpgSettingsIdentifier
#       * the full settings of the VPG              : $VpgSettings 

# Step 6: Prompt user for retention period in years
$NbYears = Read-Host "Please enter the number of years (should be less than 8)"
if ($NbYears -gt 8) {
    Write-Error "Number of years is out of scope" -ErrorAction Stop
}
$VpgSettings.LongTermRetention.SchedulerPolicy.Yearly.RetentionDuration.Count = [int]$NbYears

# Step 7: Convert settings to JSON and modify VPG settings
$VpgSettingsJson = $VpgSettings | ConvertTo-Json -Depth 7
Invoke-ApiCall -Uri "$zvmApiBase/vpgSettings/$VpgSettingsIdentifier" -Method "PUT" -Headers $Headers -Body $VpgSettingsJson

# Now we have 
#       * The basic address of the zvm              : $zvmApiBase
#       * The token to be used as a Bearer          : $token
#       * All Vpg present in the zvm                : $VpgList
#       * the id of the VPG to be modified          : $VpgIdentifier
#       * the id of the modifications (settings)    : $VpgSettingsIdentifier
#       * The full settings of VPG in Json format   : $VpgSettingsJson modified with correct nb of year

# Step 8: Commit the changes and show them
Invoke-ApiCall -Uri "$zvmApiBase/vpgSettings/$VpgSettingsIdentifier/commit" -Method "POST" -Headers $Headers

Write-Host "The VPG $VpgSettingsIdentifier has $NbYears Years of retention."
