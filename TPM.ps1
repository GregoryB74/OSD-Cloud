# tpm.osdcloud.ch
$Global:Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Test-Autopilotattestation.log"
Start-Transcript -Path (Join-Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" $Global:Transcript) -ErrorAction Ignore

Write-Host "Execute Test Autopilot Attestation" -ForegroundColor Green

Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
Install-Module -Name Autopilottestattestation -Force
Import-Module -Name Autopilottestattestation
Test-Autopilotattestation

Stop-Transcript
