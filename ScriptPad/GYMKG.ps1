
#================================================
#   [PreOS] Update Module
#================================================
if ((Get-MyComputerModel) -match 'Virtual') {
    Write-Host  -ForegroundColor Green "Setting Display Resolution to 1600x"
    Set-DisRes 1600
}

Write-Host -ForegroundColor Green "Updating OSD PowerShell Module"
Install-Module OSD -Force

Write-Host  -ForegroundColor Green "Importing OSD PowerShell Module"
Import-Module OSD -Force   

#=======================================================================
#   [OS] Params and Start-OSDCloud
#=======================================================================
$Params = @{
    OSBuild = "20H2"
    OSEdition = "Enterprise"
    OSLanguage = "en-us"
    ZTI = $true
}
Start-OSDCloud @Params

#================================================
#   PostOS Audit Mode OOBEDeploy
#================================================
Write-Host -ForegroundColor Green "Create C:\Windows\Panther\Unattend.xml"
$AuditUnattendXml = @'
<?xml version='1.0' encoding='utf-8'?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="specialize" wasPassProcessed="true">
        <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <RunSynchronous>
                <RunSynchronousCommand wcm:action="add">
                    <Order>1</Order>
                    <Description>OSDCloud Specialize</Description>
                    <Path>Powershell -ExecutionPolicy Bypass -Command Invoke-OSDSpecialize -Verbose</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>2</Order>
                    <Description>Start Autopilot.CMD</Description>
                    <Path>CMD /K START /WAIT C:\Windows\System32\Autopilot.cmd</Path>
                </RunSynchronousCommand>
            </RunSynchronous>
        </component>
    </settings>
</unattend>
'@
#================================================
#   Set Unattend.xml
#================================================
$PantherUnattendPath = 'C:\Windows\Panther'
if (-NOT (Test-Path $PantherUnattendPath)) {
    New-Item -Path $PantherUnattendPath -ItemType Directory -Force | Out-Null
}
$AuditUnattendPath = Join-Path $PantherUnattendPath 'Unattend.xml'
$AuditUnattendXml | Out-File -FilePath $AuditUnattendPath -Encoding utf8
Use-WindowsUnattend -Path 'C:\' -UnattendPath $AuditUnattendPath -Verbose

#================================================
#  [PostOS] AutopilotOOBE Configuration Staging
#================================================
Write-Host -ForegroundColor Green "Create C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json"
$AutopilotOOBEJson = @'
{
    "Assign":  {
                   "IsPresent":  true
               },
    "GroupTag":  "Mittelschulen",
    "AddToGroup": "sg-GYMKG",
    "AddToGroupOptions":  [
                    "sg-GYMKG",
                    "sg-GYMWM"
    ],
    "Hidden":  [
                   "AssignedComputerName",
                   "AssignedUser",
                   "PostAction",
                   "GroupTag",
                   "Assign"
               ],
    "PostAction":  "SysprepReboot",
    "Run":  "NetworkingWireless",
    "Docs":  "https://google.com/",
    "Title":  "EDUBS PoC Autopilot Register"
}
'@
If (!(Test-Path "C:\ProgramData\OSDeploy")) {
    New-Item "C:\ProgramData\OSDeploy" -ItemType Directory -Force | Out-Null
}
$AutopilotOOBEJson | Out-File -FilePath "C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json" -Encoding ascii -Force

#================================================
#  [PostOS] AutopilotOOBE CMD Command Line
#================================================
Write-Host -ForegroundColor Green "Create C:\Windows\System32\Autopilot.cmd"
$AutopilotCMD = @'
PowerShell -NoL -Com Set-ExecutionPolicy RemoteSigned -Force
Set Path = %PATH%;C:\Program Files\WindowsPowerShell\Scripts
Start /Wait PowerShell -NoL -C Install-Module AutopilotOOBE -Force -Verbose
Start /Wait PowerShell -NoL -C Start-AutopilotOOBE  
'@
$AutopilotCMD | Out-File -FilePath 'C:\Windows\System32\Autopilot.cmd' -Encoding ascii -Force

#================================================
#  [PostOS] OOBEDeploy Configuration
#================================================
Write-Host -ForegroundColor Green "Create C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json"
$OOBEDeployJson = @'
{
    "Autopilot":  {
                      "IsPresent":  false
                  },
    "RemoveAppx":  [
                       "CommunicationsApps",
                       "OfficeHub",
                       "People",
                       "Skype",
                       "Solitaire",
                       "Xbox",
                       "ZuneMusic",
                       "ZuneVideo"
                   ],
    "UpdateDrivers":  {
                          "IsPresent":  true
                      },
    "UpdateWindows":  {
                          "IsPresent":  true
                      }
}
'@
$OOBEDeployJson | Out-File -FilePath "C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json" -Encoding ascii -Force

#================================================
#  [PostOS] OOBEDeploy CMD Command Line
#================================================
Write-Host -ForegroundColor Green "Create C:\Windows\System32\PostOOBE.cmd"
$PostOOBECMD = @'
PowerShell -NoL -Com Set-ExecutionPolicy RemoteSigned -Force
Set Path = %PATH%;C:\Program Files\WindowsPowerShell\Scripts
Start PowerShell -NoL -W Mi
Start /Wait PowerShell -NoL -C Install-Module AutopilotOOBE -Force -Verbose
Start /Wait PowerShell -NoL -C Start-OOBEDeploy
Start /Wait PowerShell -NoL -C Restart-Computer -Force
'@

$PostOOBECMD | Out-File -FilePath 'C:\Windows\System32\PostOOBE.cmd' -Encoding ascii -Force

#=======================================================================
#   Restart-Computer
#=======================================================================
Write-Host  -ForegroundColor Green "Restarting in 20 seconds!"
Start-Sleep -Seconds 20
wpeutil reboot
