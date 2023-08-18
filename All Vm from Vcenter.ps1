# Retrieve all Vm from Vcenter

# Input connection information

$VCenterUser = Read-Host -Prompt 'Input the Vcenter full User Name (e.g. administrator@vsphere.local) '
if (!$VCenterUser)
{
    $VCenterUser = "administrator@vsphere.local"
}
$VCenterPassword = Read-Host "Enter Vcenter password" -AsSecureString
$VCenterCredential = New-Object System.Management.Automation.PSCredential($VCenterUser,$VCenterPassword)
$VcenterServer = Read-Host "Enter Vcenter server IP adress"

# Connect to Vcenter

Connect-VIServer -Force -Server $VcenterServer -Credential $VCenterCredential

# Retrieve all VM of this Vcenter 

$AllVms = Get-VM
# $AllVms | Select-Object Name, Id | Format-Table
$AllVms | Select-Object Name, Id, @{ Name = "UUID"; Expression = {(Get-View $_.Id).config.uuid}} |Format-Table
#{    "vmIdentifier": "4207156b-a76a-040d-bfe7-9ae23fea2af8.vm-27299" }
