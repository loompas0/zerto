#-------------------------------------------------
# Creates local ESXi user with admin rights and lockdown exception while the host is in lockdown mode
# Creates this user with Lockdown mode exception
# Creates this user on every host managed by the selected vCenter server
# 
# Requires PowerCLI 6.5 or higher (module based not snappin)
# Based on scripts by Wouter Kursten, Luc Dekens and others
#
# Version 1.0
# 06-18-2018
# Created by: Jim Strompolis
#
################################################
# Legal Disclaimer:
# This script is not supported under any Zerto support program or service. 
# All scripts are provided AS IS without warranty of any kind. 
# The author and Zerto further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. 
# The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. 
# In no event shall Zerto, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation, even if the author or Zerto has been advised of the possibility of such damages.
################################################
#-------------------------------------------------
#
# Load the required VMware modules (for PowerShell only)

Write-Host "Loading VMware PowerCLI Modules" -ForegroundColor Green
try	{
    get-module -listavailable vm* | import-module -erroraction stop
}
catch	{
    write-host "No Powercli found" -ForegroundColor Red
}

#Ask for connection information

$vcenter=Read-Host "Enter vCenter FQDN or IP"
$rootpassword = Read-Host "Enter ESXi host root password" -AsSecureString
$accountName = Read-Host "Enter new username to add to each host"
$accountDescription  = Read-Host "Enter new user description"
$accountPswd = Read-Host "Enter new user password" -AsSecureString
$rootuser="root"

# Connect to vCenter
$connectedvCenter = $global:DefaultVIServer

if($connectedvCenter.name -ne $vcenter){
	Connect-VIServer $vCenter -wa 0 | Out-Null
	Write-Host "Connected"
	Write-Host " "
}

# Get the host inventory from vCenter
$vmhosts = Get-VMHost

foreach($vmhost in $vmhosts){
    try {
        (get-vmhost $vmhost | get-view).ExitLockdownMode()
        write-host "Lockdown disabled for $vmhost" -foregroundcolor green
    }
    catch   {
        write-host "can't disable lockdown for $vmhost maybe it's already disabled" -foregroundcolor Red
    }

    connect-viserver -server $vmhost -user $rootuser -password ([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($rootpassword))) -wa 0 -notdefault | Out-Null

    Try {
        $account = Get-VMHostAccount -server $vmhost.name -Id $accountName -ErrorAction Stop |
        Set-VMHostAccount -server $vmhost.name -Password ([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($accountPswd))) -Description $accountDescription 
    }
    Catch   {
        $account = New-VMHostAccount -server $vmhost.name -Id $accountName -Password ([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($accountPswd))) -Description $accountDescription -UserAccount -GrantShellAccess 
    }
    
    $rootFolder = Get-Folder -Name root -Server $vmhost.name
    New-VIPermission -server $vmhost.name -Entity $rootFolder -Principal $account -Role Admin

    #Adding the new user to the Lockdown Exceptions list
    $HostAccessManager = Get-View -Server $vCenter $vmhost.ExtensionData.ConfigManager.HostAccessManager
    $HostAccessManager.UpdateLockdownExceptions($accountName)
     
      
    Disconnect-VIServer $vmhost.name -Confirm:$false  
    try {	
        (get-vmhost $vmhost | get-view).EnterLockdownMode()
        write-host "Lockdown enabled for $vmhost" -foregroundcolor green
    }
    catch   {
        write-host "can't disable lockdown for $vmhost maybe it's already Enabled?" -foregroundcolor Red}
    }


    Disconnect-VIServer -Confirm:$false
    