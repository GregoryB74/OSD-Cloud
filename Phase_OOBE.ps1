[CmdletBinding()]
param()
$ScriptName = 'Phase OOBE'
$ScriptVersion = '0.0.1'
$host.UI.RawUI.WindowTitle = $ScriptName

#####################
### Region Initialize
#####################

$Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-$ScriptName.log"
$null = Start-Transcript -Path (Join-Path "$env:SystemRoot\Temp" $Transcript) -ErrorAction Ignore

Set-ExecutionPolicy -ExecutionPolicy Bypass -Force

# Check OS version
Write-Host -ForegroundColor Yellow "[+] OS information:"
$Computerinfo = Get-ComputerInfo
$PCName = $Computerinfo.CsName
$manufacturer = $Computerinfo.csmanufacturer
$model = $Computerinfo.csmodel
$OS = $Computerinfo.OSName
$Systemtype = $Computerinfo.CsPCSystemType
$BIOSVersion = $Computerinfo.BIOSVersion

$OSInfo = Get-WmiObject Win32_OperatingSystem
$serial = $osinfo.SerialNumber
$OSversion = $OSInfo.version

Write-Host -ForegroundColor Green "PC Name: $PCName"
Write-Host -ForegroundColor Green "Manufacturer: $manufacturer"
Write-Host -ForegroundColor Green "Model: $model"
Write-Host -ForegroundColor Green "Serial number: $Serial"
Write-Host -ForegroundColor Green "OS Name: $OS"
Write-Host -ForegroundColor Green "OS version: $OSversion"
Write-Host -ForegroundColor Green "OS version: $Systemtype"
Write-Host -ForegroundColor Green "BIOS version: $BIOSVersion"

# 10.0.19042 -> 20H2
# 10.0.19044 -> 21H2
# 10.0.19045 -> 22H2

$SupportedVersions = @("10.0.19045")
Write-host  -ForegroundColor Yellow "[+] Checking if the device has a supported OS version"
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
Write-host  -ForegroundColor Yellow "[+] Checking if the device has a required TPM 2.0 version"
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
Write-host  -ForegroundColor Yellow "[+] Checking Secure boot enabled"
$SBstate = Confirm-SecureBootUEFI

if ($SBstate -eq $true)
{
    Write-Host -ForegroundColor Green "Secure boot is enabled"
}
else 
{
    Write-Host -ForegroundColor red "Secure boot is disabled"
    Write-Host -ForegroundColor red "Process can not continue. Please check your secureboot info in the BIOS"
    $Site = "www.google.com/search?q=Enable secure boot on $manufacturer $model"
    Start-Process $Site
    Exit
}

# Check Intune, Azure & Autopilot
Write-Host -ForegroundColor Green "[+] Installing WindowsAutoPilotIntune PowerShell Module"
Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
Install-Module -Name WindowsAutoPilotIntune



