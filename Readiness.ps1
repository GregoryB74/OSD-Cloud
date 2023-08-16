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
$ScriptName = 'MWP - Check readiness'
$ScriptVersion = '0.0.1'

#####################
### Region Initialize
#####################

$Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-$ScriptName.log"
$null = Start-Transcript -Path (Join-Path "$env:SystemRoot\Temp" $Transcript) -ErrorAction Ignore

#Checking which platform we are running from when script is executed
If ($env:SystemDrive -eq 'X:') 
{
    $WindowsPhase = 'WinPE'
} 
Else 
{
	$ImageState = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\State' -ErrorAction Ignore).ImageState
	If ($env:UserName -eq 'defaultuser0') 
	{
		$WindowsPhase = 'OOBE'
	} 
	ElseIf ($ImageState -eq 'IMAGE_STATE_SPECIALIZE_RESEAL_TO_OOBE') 
	{
		$WindowsPhase = 'Specialize'
	} 
	ElseIf ($ImageState -eq 'IMAGE_STATE_SPECIALIZE_RESEAL_TO_AUDIT') 
	{
		$WindowsPhase = 'AuditMode'
	} 
	Else 
	{
		$WindowsPhase = 'Windows'
	}
}

Write-Host -ForegroundColor Yellow "[+] $ScriptName $ScriptVersion ($WindowsPhase Phase)"
#Invoke-Expression -Command (Invoke-RestMethod -Uri functions.osdcloud.com)

# End Region Initialize
if ((Get-MyComputerModel) -match 'Virtual') 
{
    Write-Host  -ForegroundColor Green "[+] Setting Display Resolution to 1600x"
    Set-DisRes 1600
}

#####################
### Region Transport Layer Security (TLS) 1.2
#####################

Write-Host -ForegroundColor Yellow "[+] Transport Layer Security (TLS) 1.2"
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# End Region TLS

#####################
### Region WinPE
#####################

If ($WindowsPhase -eq 'WinPE') 
{
	Write-Host -ForegroundColor Yellow "[+] WINPE Phase specific actions."
	Write-Host -ForegroundColor Yellow "Launching WINPE steps."
	Invoke-WebPSScript "https://raw.githubusercontent.com/GregoryB74/OSD-Cloud/main/Phase_WINPE.ps1"
	Read-Host
	$null = Stop-Transcript -ErrorAction Ignore
}

# End Region WinPE

#####################
### Region Specialize
#####################

If ($WindowsPhase -eq 'Specialize') 
{
	Write-Host -ForegroundColor Red "This tool is not meant to be executed in the Specialize phase, exiting. Please press a key."
	Read-Host
	$null = Stop-Transcript -ErrorAction Ignore
	Exit
}

# End Region Specialize

#####################
### Region AuditMode
#####################

If ($WindowsPhase -eq 'AuditMode') 
{
    Write-Host -ForegroundColor Red "This tool is not meant to be executed in the AuditMode phase, exiting. Please press a key."
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
	Write-Host -ForegroundColor Yellow "[+] OOBE Phase specific actions."
	Write-Host -ForegroundColor Yellow "Launching OOBE steps."
	Invoke-WebPSScript "https://raw.githubusercontent.com/GregoryB74/OSD-Cloud/main/Phase_OOBE.ps1"
	Read-Host
	$null = Stop-Transcript -ErrorAction Ignore
}

# End Region OOBE

#####################
### Region Windows
#####################

If ($WindowsPhase -eq 'Windows') 
{
    Write-Host -ForegroundColor Red "This tool is not meant to be executed in the the Windows deployed phase, exiting. Please press a key."
	Read-Host
	$null = Stop-Transcript -ErrorAction Ignore
	Exit
}

# End Region Windows