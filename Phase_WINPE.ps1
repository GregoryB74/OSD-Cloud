Write-Host -ForegroundColor Green "Starting OSD Process"
Start-Sleep -Seconds 5

#Make sure I have the latest OSD Content
Write-Host -ForegroundColor Green "Updating OSD PowerShell Module"
Install-Module OSD -Force

Write-Host  -ForegroundColor Green "Importing OSD PowerShell Module"
Import-Module OSD -Force

#================================================
#   [PreOS] VM Update resolution
#================================================
if ((Get-MyComputerModel) -match 'Virtual') 
{
    Write-Host  -ForegroundColor Green "Setting Display Resolution to 1600x"
    Set-DisRes 1600
}

#=======================================================================
#   [OS] Params and Start-OSDCloud
#=======================================================================

# For troubleshooting: start-process cmd
# For troubleshooting: start-sleep -s 3600

# Check USB Key drive
Write-Host  -ForegroundColor Green "Checking USB drive"
$BootFromKey = $false

if(Get-USBPartition)
{
    Write-Host  -ForegroundColor Green "USB key found"
    Write-Host  -ForegroundColor Green "Searching Wim file"
    $USBPartitions = Get-USBPartition
    foreach($USBPartition in $USBPartitions)
    {
        $driveletter = $USBPartition.driveletter
        $Wimpath = $driveletter + ":\OSDCloud\OS\install.wim"
        if(Test-Path $Wimpath)
        {
            Write-Host  -ForegroundColor Green "Wim file found, launching confirmation message."
            # Start-OSDCloud @Params
            $newobject = new-object -comobject wscript.shell
            $Message = $newobject.popup("Would you like to proceed with local install (Yes), or install from Internet (No) ?",10," Confirmation (Message will close in 10 seconds ",1)
            if ($Message -eq '1')
            {
                Start-OSDCloud -FindImageFile -ZTI
                $BootFromKey = $true
                break
            }
            else 
            {
                $BootFromKey = $false
            }
        }
        else
        {
            Write-Host  -ForegroundColor Yellow "No Wim file found on $driveletter"
            <# Action when this condition is true #>
        }
    }
}
if($BootFromKey -eq $false)
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
    Start-OSDCloud @Params
}

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
If (!(Test-Path "C:\ProgramData\OSDeploy")) 
{
    New-Item "C:\ProgramData\OSDeploy" -ItemType Directory -Force | Out-Null
}
$OOBEDeployJson | Out-File -FilePath "C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json" -Encoding ascii -Force

#================================================
#  [PostOS] AutopilotOOBE CMD Command Line
#================================================

Write-Host -ForegroundColor Green "Create C:\Windows\System32\OOBE.cmd"
$OOBECMD = @'
PowerShell -NoL -Com Set-ExecutionPolicy RemoteSigned -Force
Set Path = %PATH%;C:\Program Files\WindowsPowerShell\Scripts
Start /Wait PowerShell -NoL -C Install-Module OSD -Force -Verbose
Start /Wait PowerShell -NoL -C Invoke-WebRequest https://github.com/GregoryB74/Tools/raw/main/CMTrace.exe -OutFile "C:\Windows\System32\CMTrace.exe"
Start /Wait PowerShell -NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/GregoryB74/OSD-Cloud/main/Start-AutopilotPreCheck.ps1
Start /Wait PowerShell -NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/GregoryB74/OSD-Cloud/main/Start-TPMCheck.ps1
Start /Wait PowerShell -NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/GregoryB74/OSD-Cloud/main/Start-CleanUp.ps1
Start /Wait PowerShell -NoL -C Restart-Computer -Force
'@
$OOBECMD | Out-File -FilePath 'C:\Windows\System32\OOBE.cmd' -Encoding ascii -Force

# Start /Wait PowerShell -NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/GregoryB74/OSD-Cloud/main/Start-AutopilotOOBE.ps1
# Start /Wait PowerShell -NoL -C Start-OOBEDeploy
# Start /Wait PowerShell -NoL -C Install-Module AutopilotOOBE -Force -Verbose

#================================================
#  [PostOS] SetupComplete CMD Command Line
#================================================
Write-Host -ForegroundColor Green "Create C:\Windows\Setup\Scripts\SetupComplete.cmd"
$SetupCompleteCMD = @'
powershell.exe -Command Set-ExecutionPolicy RemoteSigned -Force
powershell.exe -Command "& {IEX (IRM https://raw.githubusercontent.com/GregoryB74/OSD-Cloud/main/Set-OOBETasksV2.ps1)}"
'@
$SetupCompleteCMD | Out-File -FilePath 'C:\Windows\Setup\Scripts\SetupComplete.cmd' -Encoding ascii -Force

#=======================================================================
#   Restart-Computer
#=======================================================================
Write-Host  -ForegroundColor Green "Restarting in 20 seconds!"
Start-Sleep -Seconds 20
wpeutil reboot
