# Enter credential
$ZertoUser = Read-Host -Prompt 'Input the Zerto user name'
$ZertoPassword = Read-Host "Enter Zerto password" -AsSecureString
$ZertoCredential = New-Object System.Management.Automation.PSCredential($ZertoUser,$ZertoPassword)
$ZertoServer = Read-Host "Enter ZVM server IP adress"
$ZertoPort="9669"
# Write-Output $ZertoUser
# Write-Output $ZertoPassword
# $plainPwd =[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($ZertoPassword))
# Write-Output $plainPwd
# Write-Output $Credential
#
# Connect to ZVM 
Remove-ZvmSslCheck
Connect-Zvm -hostName $ZertoServer -credential $ZertoCredential 
# Write-Output $Token
get-zvmvpg