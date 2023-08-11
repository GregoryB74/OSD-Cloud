<#PSScriptInfo
.VERSION 0.0.1
.AUTHOR Joachim Becker | Sword Technologies
.COMPANYNAME Sword Technologies
.COPYRIGHT (c) 2023 Joachim Becker Sword Technologies. All rights reserved.
.TAGS MWP Check WinPE OOBE Windows AutoPilot
.LICENSEURI
.PROJECTURI https://mwp.selecta.com
.ICONURI 
.EXTERNALMODULEDEPENDENCIES 
.REQUIREDSCRIPTS 
.EXTERNALSCRIPTDEPENDENCIES 
.RELEASENOTES
Script should be executed in a Command Prompt using the following command
powershell Invoke-Expression -Command (Invoke-RestMethod -Uri xxx.selecta.com)
This is abbreviated as
powershell iex (irm sandbox.xxx.selecta.com)
#>
# Requires -RunAsAdministrator
<#
.SYNOPSIS
    PowerShell Script which supports the MWP environment
.DESCRIPTION
    PowerShell Script which supports the MWP environment
.NOTES
    Version 0.0.1
.LINK
    https://mwp.selecta.com/requirements/mwp-readiness.ps1
.EXAMPLE
    powershell iex (irm check.selecta.com)
#>
[CmdletBinding()]
param()
$ScriptName = 'check.selecta.com'
$ScriptVersion = '0.0.1'

#####################
### Region Initialize
#####################

$Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-$ScriptName.log"
$null = Start-Transcript -Path (Join-Path "$env:SystemRoot\Temp" $Transcript) -ErrorAction Ignore

#Checking which platform we are running from when script is executed
If ($env:SystemDrive -eq 'X:') {
    $WindowsPhase = 'WinPE'
} Else {
	$ImageState = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\State' -ErrorAction Ignore).ImageState
	If ($env:UserName -eq 'defaultuser0') {
		$WindowsPhase = 'OOBE'
	} ElseIf ($ImageState -eq 'IMAGE_STATE_SPECIALIZE_RESEAL_TO_OOBE') {
		$WindowsPhase = 'Specialize'
	} ElseIf ($ImageState -eq 'IMAGE_STATE_SPECIALIZE_RESEAL_TO_AUDIT') {
		$WindowsPhase = 'AuditMode'
	} Else {
		$WindowsPhase = 'Windows'
	}
}

Write-Host -ForegroundColor Green "[+] $ScriptName $ScriptVersion ($WindowsPhase Phase)"
Invoke-Expression -Command (Invoke-RestMethod -Uri functions.osdcloud.com)

# End Region Initialize


#####################
### Region Transport Layer Security (TLS) 1.2
#####################

Write-Host -ForegroundColor Green "[+] Transport Layer Security (TLS) 1.2"
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# End Region TLS

#####################
### Region WinPE
#####################

If ($WindowsPhase -eq 'WinPE') {
    	Write-Host -ForegroundColor Green "WinPE Phase specific actions."
	Read-Host
	$null = Stop-Transcript -ErrorAction Ignore
}

# End Region WinPE

#####################
### Region Specialize
#####################

If ($WindowsPhase -eq 'Specialize') {
	Write-Host -ForegroundColor Red "This tool is not meant to be executed in the Specialize phase, exiting. Please press a key."
	Read-Host
	$null = Stop-Transcript -ErrorAction Ignore
	Exit
}

# End Region Specialize

#####################
### Region AuditMode
#####################

If ($WindowsPhase -eq 'AuditMode') {
    	Write-Host -ForegroundColor Red "Thisl too is not meant to be executed in the AuditMode phase, exiting. Please press a key."
	Read-Host
	$null = Stop-Transcript -ErrorAction Ignore
	Exit
}

# End Region Audit Mode

#####################
### Region OOBE
#####################

If ($WindowsPhase -eq 'OOBE') 
{
	Write-Host -ForegroundColor Green "OOBE Phase specific actions."
	
	# Check OS version
	$OSInfo = Get-WmiObject Win32_OperatingSystem
	$serial = $osinfo.SerialNumber
	$OSversion = $OSInfo.version
	Write-Host -ForegroundColor Green "Serial number: $serial"
	Write-Host -ForegroundColor Green "OS version: $OSversion"

	# 10.0.19042 -> 20H2
	# 10.0.19044 -> 21H2
	# 10.0.19045 -> 22H2

	$SupportedVersions = @("10.0.19045")
	Write-host  -ForegroundColor Yellow "Checking if the device has a supported OS version"
	if ($OSversion -in $SupportedVersions)
	{
		Write-Host -ForegroundColor Green "Version $OSversion is OK"
	}
	else 
	{
		Write-Host -ForegroundColor red "Not a good version"
        Exit
	}
	
	# Check TPM
	Write-host  -ForegroundColor Yellow "Checking if the device has a required TPM 2.0 version"
	$TPMversion = Get-WmiObject -Namespace "root\cimv2\security\microsofttpm" -Query "Select SpecVersion from win32_tpm" | Select-Object specversion
	if($TPMVersion.SpecVersion -like "*1.2*")
	{
		Write-host  -ForegroundColor red "TPM Version is 1.2. Attestation is not going to work!!!!"
        Exit
	}
	elseif($TPMVersion.SpecVersion -like "*1.15*")
	{
		Write-host  -ForegroundColor red "TPM Version is 1.15. You are probably running this script on a VM aren't you? Attestation doesn't work on a VM!"
        Exit
	}
	else 
	{
		Write-host  -ForegroundColor green "TPM Version is 2.0"
	}

	# Check Secure boot
    Write-host  -ForegroundColor Yellow "Checking Secure boot enabled"
	$SBstate = Confirm-SecureBootUEFI

	if ($SBstate -eq $true)
	{
		Write-Host -ForegroundColor Green "Secure boot is enabled"
	}
	else 
	{
		Write-Host -ForegroundColor red "Secure boot is disabled"
        Exit
	}
	
	# Check Intune, Azure & Autopilot
	Write-Host -ForegroundColor Green "Installing WindowsAutoPilotIntune PowerShell Module"
	Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
	Install-Module -Name WindowsAutoPilotIntune
	
	


	Read-Host
	$null = Stop-Transcript -ErrorAction Ignore
}

# End Region OOBE

#####################
### Region Windows
#####################

If ($WindowsPhase -eq 'Windows') {
    	Write-Host -ForegroundColor Red "This tool is not meant to be executed in the the Windows deployed phase, exiting. Please press a key."
	Read-Host
	$null = Stop-Transcript -ErrorAction Ignore
	Exit
}

# End Region Windows


