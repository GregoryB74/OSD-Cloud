# Check OS & Azure device
# Install WindowsAutoPilotIntune Moduule

$Global:Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Check-AutopilotPrerequisites.log"
Start-Transcript -Path (Join-Path "C:\Windows\Temp\OSD\" $Global:Transcript) -ErrorAction Ignore

# Check OS version
$OSInfo = Get-WmiObject Win32_OperatingSystem
$serial = $osinfo.SerialNumber
$OSversion = $OSInfo.version
Write-Host -ForegroundColor Green "Serial number: $serial"
Write-Host -ForegroundColor Green "OS version: $OSversion"


$SupportedVersions = @("10.0.19045")

# 10.0.19042 -> 20H2
# 10.0.19044 -> 21H2
# 10.0.19045 -> 22H2

if ($OSversion -in $SupportedVersions)
{
    Write-Host -ForegroundColor Green "Version $OSversion is OK"
}
else 
{
    Write-Host -ForegroundColor red "Not a good version"
}

# Check TPM



# Check Intune, Azure & Autopilot
Write-Host -ForegroundColor Green "Installing WindowsAutoPilotIntune PowerShell Module"
Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
Install-Module -Name WindowsAutoPilotIntune

