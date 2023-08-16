Write-Host -ForegroundColor Green "Starting OSDCloud ZTI"
Start-Sleep -Seconds 5

#Make sure I have the latest OSD Content
Write-Host -ForegroundColor Green "Updating OSD PowerShell Module"
Install-Module OSD -Force

Write-Host  -ForegroundColor Green "Importing OSD PowerShell Module"
Import-Module OSD -Force

#Start OSDCloudScriptPad
Write-Host -ForegroundColor Green "Start OSDPad"
#Start-OSDPad -RepoOwner GregoryB74 -RepoName OSD-Cloud -RepoFolder ScriptPad -BrandingTitle 'Gregory B OSD Cloud Deployment'

#================================================
#   [PreOS] Update Module
#================================================
if ((Get-MyComputerModel) -match 'Virtual') 
{
    Write-Host  -ForegroundColor Green "Setting Display Resolution to 1600x"
    Set-DisRes 1600
}

#=======================================================================
#   [OS] Params and Start-OSDCloud
#=======================================================================
$Params = @{
    OSVersion = "Windows 10"
    OSBuild = "22H2"
    OSEdition = "Enterprise"
    OSLanguage = "en-us"
    OSLicense = "Volume"
    ZTI = $true
    Firmware = $false
}

# Check USB Key drive
$DRIVES = (Get-CimInstance -Class Win32_DiskDrive -Filter 'InterfaceType = "USB"' -KeyOnly | Get-CimAssociatedInstance -ResultClassName Win32_DiskPartition -KeyOnly | Get-CimAssociatedInstance -ResultClassName Win32_LogicalDisk).DeviceID

if($DRIVES -ne $null)
    {
    Write-Host  -ForegroundColor Green "USB key found"
    $Drive = $DRIVE[0]
    Write-Host  -ForegroundColor Green "Letter of USB key is: $drive"
    $Path = $DRIVE + "\OSD\Install.wim"
    $Params = @{
        FindImageFile = $Path
}
    }
else
    {
    Write-Host  -ForegroundColor Green "NO USB key found, Windows will be installed from internet !"
    $Params = @{
    OSVersion = "Windows 10"
    OSBuild = "22H2"
    OSEdition = "Enterprise"
    OSLanguage = "en-us"
    OSLicense = "Volume"
    ZTI = $true
    Firmware = $false
}
    }

Start-OSDCloud @Params

#================================================
#  [PostOS] OOBEDeploy Configuration
#================================================
Write-Host -ForegroundColor Green "Create C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json"
$OOBEDeployJson = @'
{
    "AddNetFX3":  {
                      "IsPresent":  true
                  },
    "Autopilot":  {
                      "IsPresent":  false
                  },
    "RemoveAppx":  [
                    "MicrosoftTeams",
                    "Microsoft.BingWeather",
                    "Microsoft.BingNews",
                    "Microsoft.GamingApp",
                    "Microsoft.GetHelp",
                    "Microsoft.Getstarted",
                    "Microsoft.Messaging",
                    "Microsoft.MicrosoftOfficeHub",
                    "Microsoft.MicrosoftSolitaireCollection",
                    "Microsoft.MicrosoftStickyNotes",
                    "Microsoft.MSPaint",
                    "Microsoft.People",
                    "Microsoft.PowerAutomateDesktop",
                    "Microsoft.StorePurchaseApp",
                    "Microsoft.Todos",
                    "microsoft.windowscommunicationsapps",
                    "Microsoft.WindowsFeedbackHub",
                    "Microsoft.WindowsMaps",
                    "Microsoft.WindowsSoundRecorder",
                    "Microsoft.Xbox.TCUI",
                    "Microsoft.XboxGameOverlay",
                    "Microsoft.XboxGamingOverlay",
                    "Microsoft.XboxIdentityProvider",
                    "Microsoft.XboxSpeechToTextOverlay",
                    "Microsoft.YourPhone",
                    "Microsoft.ZuneMusic",
                    "Microsoft.ZuneVideo"
                   ],
    "UpdateDrivers":  {
                          "IsPresent":  true
                      },
    "UpdateWindows":  {
                          "IsPresent":  true
                      }
}
'@
If (!(Test-Path "C:\ProgramData\OSDeploy")) {
    New-Item "C:\ProgramData\OSDeploy" -ItemType Directory -Force | Out-Null
}
$OOBEDeployJson | Out-File -FilePath "C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json" -Encoding ascii -Force

#================================================
#  [PostOS] AutopilotOOBE Configuration Staging
#================================================
#Write-Host -ForegroundColor Green "Define Computername:"
#$Serial = Get-WmiObject Win32_bios | Select-Object -ExpandProperty SerialNumber
#$TargetComputername = $Serial.Substring(4,3)

#$AssignedComputerName = "AkosCloud-$TargetComputername"
#Write-Host -ForegroundColor Red $AssignedComputerName
#Write-Host ""

#Write-Host -ForegroundColor Green "Create C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json"
#$AutopilotOOBEJson = @"
#{
#    "AssignedComputerName" : "$AssignedComputerName",
#    "AddToGroup":  "AADGroupX",
#    "Assign":  {
#                   "IsPresent":  true
#               },
#    "GroupTag":  "GroupTagXXX",
#    "Hidden":  [
#                   "AddToGroup",
#                   "AssignedUser",
#                   "PostAction",
#                   "GroupTag",
#                   "Assign"
#               ],
#    "PostAction":  "Quit",
#    "Run":  "NetworkingWireless",
#    "Docs":  "https://google.com/",
#    "Title":  "Autopilot Manual Register"
#}
#"@
#
#If (!(Test-Path "C:\ProgramData\OSDeploy")) {
#    New-Item "C:\ProgramData\OSDeploy" -ItemType Directory -Force | Out-Null
#}
#$AutopilotOOBEJson | Out-File -FilePath "C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json" -Encoding ascii -Force

#================================================
#  [PostOS] AutopilotOOBE CMD Command Line
#================================================
Write-Host -ForegroundColor Green "Create C:\Windows\System32\OOBE.cmd"
$OOBECMD = @'
PowerShell -NoL -Com Set-ExecutionPolicy RemoteSigned -Force
Set Path = %PATH%;C:\Program Files\WindowsPowerShell\Scripts
Start /Wait PowerShell -NoL -C Install-Module AutopilotOOBE -Force -Verbose
Start /Wait PowerShell -NoL -C Install-Module OSD -Force -Verbose
Start /Wait PowerShell -NoL -C Invoke-WebRequest https://github.com/GregoryB74/Tools/raw/main/CMTrace.exe -OutFile "C:\Windows\System32\CMTrace.exe"
Start /Wait PowerShell -NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/GregoryB74/OSD-Cloud/main/AP-Prereq.ps1
Start /Wait PowerShell -NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/GregoryB74/OSD-Cloud/main/Start-AutopilotOOBE.ps1
Start /Wait PowerShell -NoL -C Start-OOBEDeploy
Start /Wait PowerShell -NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/GregoryB74/OSD-Cloud/main/TPM.ps1
Start /Wait PowerShell -NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/GregoryB74/OSD-Cloud/main/CleanUp.ps1
Start /Wait PowerShell -NoL -C Restart-Computer -Force
'@
$OOBECMD | Out-File -FilePath 'C:\Windows\System32\OOBE.cmd' -Encoding ascii -Force

# Options:
# Start /Wait PowerShell -NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/GregoryB74/OSD-Cloud/main/Set-KeyboardLanguage.ps1
# Start /Wait PowerShell -NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/GregoryB74/OSD-Cloud/main/Install-EmbeddedProductKey.ps1
# Start /Wait PowerShell -NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/GregoryB74/OSD-Cloud/main/Lenovo_BIOS_Settings.ps1


#================================================
#  [PostOS] SetupComplete CMD Command Line
#================================================
Write-Host -ForegroundColor Green "Create C:\Windows\Setup\Scripts\SetupComplete.cmd"
$SetupCompleteCMD = @'
powershell.exe -Command Set-ExecutionPolicy RemoteSigned -Force
powershell.exe -Command "& {IEX (IRM https://raw.githubusercontent.com/GregoryB74/OSD-Cloud/main/oobetasks.ps1)}"
'@
$SetupCompleteCMD | Out-File -FilePath 'C:\Windows\Setup\Scripts\SetupComplete.cmd' -Encoding ascii -Force

#=======================================================================
#   Restart-Computer
#=======================================================================
Write-Host  -ForegroundColor Green "Restarting in 20 seconds!"
Start-Sleep -Seconds 20
wpeutil reboot
