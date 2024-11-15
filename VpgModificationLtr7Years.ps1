# Vpg modification ltr 7 Years 

# first get credential and token to be used 
# use json file to connect to all sites
. ./connect-secret.ps1
# Now that we have a token because of successful Keycloak authentication, we can proceed with Zerto REST API calls 

#########################################
# Second Retreive VPG identifier        #
#########################################


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

# write-output $result
$result | Select-Object VpgIdentifier, VPGName,VMsCount, SourceSite, TargetSite, ActualRPO, IOPS, ThroughputInMB | format-table 
# $VpgName = $result.VpgName
# $VpgId = $result.VpgIdentifier

# lets print VPG To choose the right one 
function Show-VPG-List
{
    
    $textline = “$i : Press ‘$i’ for choosing VPG : *** $VpgName *** ($VpgId).”
   # write Menu
    Write-Host $textline -ForegroundColor Green

}

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

#VpgIndentifier is in variable $VpgIdentifier we will use it later on 
# Now we have 
#       * the id of the VPG to be modified          : $VpgIdentifier

#########################################
# Third Lets create a VPG Setting         #
#########################################

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


# VpgSettingsIndentifier is in variable $VpgSettingsIdentifier we will use it later on to manipulate
# Now we have 
#       * the id of the VPG to be modified          : $VpgIdentifier
#       * the id of the modifications (settings)    : $VpgSettingsIdentifier


#########################################
# Fourth Lets retrieve all VPG Setting  #
#########################################

$Headers = @{
    "Content-Type"  = "application/json"
    Authorization = "Bearer ${token}"
    Accept = "application/json"
}

$UriApi = $zvmApiBase + "vpgSettings/" + $VpgSettingsIdentifier


$result = Invoke-RestMethod -Uri $UriApi  -Headers $Headers -Method Get  -SkipCertificateCheck

$VpgSettings = $result


# all VpgSettings information is in variable $VpgSettings we will use it later on to manipulate
# Now we have 
#       * the id of the VPG to be modified          : $VpgIdentifier
#       * the id of the modifications (settings)    : $VpgSettingsIdentifier
#       * the full settings of the VPG              : $VpgSettings 


##############################################
# Fith Enter nb year and Change VpgSettings  #
##############################################

#  Read the number of years and put it in Nb Years
#  to be used in  $VpgSettings.LongTermRetention.SchedulerPolicy.Yearly.RetentionDuration    
# 

$NbYearsString = Read-Host "Please enter Number of years : (should be less than 8)"
$NbYears = [int]$NbYearsString

if ($NbYears -gt 8) 
{
    Write-Error "Number of year is out of scope" -ErrorAction Stop
}

$VpgSettings.LongTermRetention.SchedulerPolicy.Yearly.RetentionDuration.Count = $NbYears

# put the variable $VpgSettings to Json format

$VpgSettingsJson = $VpgSettings | ConvertTo-Json -Depth 7
# $VpgSettingsJson = "'" + $VpgSettingsJson + "'"


# Now we have 
#       * the id of the VPG to be modified          : $VpgIdentifier
#       * the id of the modifications (settings)    : $VpgSettingsIdentifier
#       * the full settings of the VPG              : $VpgSettings modified with correct number of years
#       * The full settings of VPG in Json format   : $VpgSettingsJson


##############################################
# Sixth  Modify Vpg settings                  #
##############################################

# Api call

$Headers = @{
    "Content-Type"  = "application/json"
    Authorization = "Bearer ${token}"
    Accept = "application/json"
}
$Body = $VpgSettingsJson 
$UriApi = $zvmApiBase + "vpgSettings/" + $VpgSettingsIdentifier


$result = Invoke-RestMethod -Uri $UriApi  -Headers $Headers  -Body $Body -Method Put  -SkipCertificateCheck

# Now we have 
#       * the id of the VPG to be modified          : $VpgIdentifier
#       * the id of the modifications (settings)    : $VpgSettingsIdentifier
#       * the full settings of the VPG              : $VpgSettings modified with correct number of years
#       * The full settings of VPG in Json format   : $VpgSettingsJson


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

Write-Host $result