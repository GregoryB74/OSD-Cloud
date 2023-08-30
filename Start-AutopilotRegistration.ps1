
$Autopilot_Load={
	#TODO: Initialize Form Controls here
	$Grouptags = @('AT_Desktop', 'AT_Kiosk_sleepOFF', 'AT_Kiosk_sleepON', 'AT_Laptop', 'AT_SharedDesktop', 'BE_Desktop', 'BE_Kiosk_sleepOFF', 'BE_Kiosk_sleepON', 'BE_Laptop', 'BE_SharedDesktop', 'CH_Desktop', 'CH_Kiosk_sleepOFF', 'CH_Kiosk_sleepON', 'CH_Laptop', 'CH_SharedDesktop', 'DE_Desktop', 'DE_Kiosk_sleepOFF', 'DE_Kiosk_sleepON', 'DE_Laptop', 'DE_SharedDesktop', 'DK_Desktop', 'DK_Kiosk_sleepOFF', 'DK_Kiosk_sleepON', 'DK_Laptop', 'DK_SharedDesktop', 'ES_Desktop', 'ES_Kiosk_sleepOFF', 'ES_Kiosk_sleepON', 'ES_Laptop', 'ES_SharedDesktop', 'FI_Desktop', 'FI_Kiosk_sleepOFF', 'FI_Kiosk_sleepON', 'FI_Laptop', 'FI_SharedDesktop', 'FR_Desktop', 'FR_Kiosk_sleepOFF', 'FR_Kiosk_sleepON', 'FR_Laptop', 'FR_SharedDesktop', 'HQ_Desktop', 'HQ_Kiosk_sleepOFF', 'HQ_Kiosk_sleepON', 'HQ_Laptop', 'HQ_SharedDesktop', 'IR_Desktop', 'IR_Kiosk_sleepOFF', 'IR_kiosk_sleepON', 'IR_Laptop', 'IR_SharedDesktop', 'IT_Desktop', 'IT_Digiprint_Kiosk', 'IT_Kiosk_sleepOFF', 'IT_Kiosk_sleepON', 'IT_Laptop', 'IT_SharedDesktop', 'NL_Desktop', 'NL_Kiosk_sleepOFF', 'NL_Kiosk_sleepON', 'NL_SharedDesktop', 'NL_Laptop', 'NL_Roaster_Desktop', 'NL_Roaster_Kiosk_sleepON', 'NL_Roaster_Kiosk_sleepOFF', 'NL_Roaster_Laptop', 'RO_SharedDesktop', 'NL_Vending_Kiosk', 'NO_Desktop', 'NO_Kiosk_sleepOFF', 'NO_Kiosk_sleepON', 'NO_Laptop', 'NO_SharedDesktop', 'SE_Desktop', 'SE_Kiosk_sleepOFF', 'SE_Kiosk_sleepON', 'SE_Laptop', 'SE_SharedDesktop', 'UK_Desktop', 'UK_Kiosk_sleepOFF', 'UK_Kiosk_sleepON', 'UK_Laptop', 'UK_SharedDesktop')
	foreach ($Grouptag in $Grouptags)
	{
		$CBX_GroupTag.Items.Add($Grouptag)
		$CBX_GroupTag.SelectedIndex = 0
	}
	$Global:RegAutoPilot = Get-ItemProperty 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Provisioning\Diagnostics\AutoPilot'
	
	Write-Host -ForegroundColor Gray "IsAutoPilotDisabled: $($Global:RegAutoPilot.IsAutoPilotDisabled)"
	Write-Host -ForegroundColor Gray "CloudAssignedForcedEnrollment: $($Global:RegAutoPilot.CloudAssignedForcedEnrollment)"
	Write-Host -ForegroundColor Gray "CloudAssignedTenantDomain: $($Global:RegAutoPilot.CloudAssignedTenantDomain)"
	Write-Host -ForegroundColor Gray "CloudAssignedTenantId: $($Global:RegAutoPilot.CloudAssignedTenantId)"
	Write-Host -ForegroundColor Gray "CloudAssignedTenantUpn: $($Global:RegAutoPilot.CloudAssignedTenantUpn)"
	Write-Host -ForegroundColor Gray "CloudAssignedLanguage: $($Global:RegAutoPilot.CloudAssignedLanguage)"
	
	if ($Global:RegAutoPilot.CloudAssignedForcedEnrollment -eq 1)
	{
		Write-Host -ForegroundColor Gray "TenantId: $($Global:RegAutoPilot.TenantId)"
		Write-Host -ForegroundColor Gray "CloudAssignedMdmId: $($Global:RegAutoPilot.CloudAssignedMdmId)"
		Write-Host -ForegroundColor Gray "AutopilotServiceCorrelationId: $($Global:RegAutoPilot.AutopilotServiceCorrelationId)"
		Write-Host -ForegroundColor Gray "CloudAssignedOobeConfig: $($Global:RegAutoPilot.CloudAssignedOobeConfig)"
		Write-Host -ForegroundColor Gray "CloudAssignedTelemetryLevel: $($Global:RegAutoPilot.CloudAssignedTelemetryLevel)"
		Write-Host -ForegroundColor Gray "IsDevicePersonalized: $($Global:RegAutoPilot.IsDevicePersonalized)"
		Write-Host -ForegroundColor Gray "SetTelemetryLevel_Succeeded_With_Level: $($Global:RegAutoPilot.SetTelemetryLevel_Succeeded_With_Level)"
		Write-Host -ForegroundColor Gray "IsForcedEnrollmentEnabled: $($Global:RegAutoPilot.IsForcedEnrollmentEnabled)"
		Write-Host -ForegroundColor Green "This device has already been Autopilot Registered. Registration will not be enabled"
		Start-Sleep -Seconds 2
		$AutopilotRegistered = $true
	}
	if ($AutopilotRegistered -eq $true)
	{
		$BTN_Register.Text = "Continue"
		$LBL_selectGroupTag.Text = "This device has already been Autopilot Registered. Registration will not be enabled"
		$CBX_GroupTag.Enabled = $false
	}
	
}

#region Control Helper Functions
function Update-ComboBox
{
<#
	.SYNOPSIS
		This functions helps you load items into a ComboBox.
	
	.DESCRIPTION
		Use this function to dynamically load items into the ComboBox control.
	
	.PARAMETER ComboBox
		The ComboBox control you want to add items to.
	
	.PARAMETER Items
		The object or objects you wish to load into the ComboBox's Items collection.
	
	.PARAMETER DisplayMember
		Indicates the property to display for the items in this control.
	
	.PARAMETER Append
		Adds the item(s) to the ComboBox without clearing the Items collection.
	
	.EXAMPLE
		Update-ComboBox $combobox1 "Red", "White", "Blue"
	
	.EXAMPLE
		Update-ComboBox $combobox1 "Red" -Append
		Update-ComboBox $combobox1 "White" -Append
		Update-ComboBox $combobox1 "Blue" -Append
	
	.EXAMPLE
		Update-ComboBox $combobox1 (Get-Process) "ProcessName"
	
	.NOTES
		Additional information about the function.
#>
	
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNull()]
		[System.Windows.Forms.ComboBox]
		$ComboBox,
		[Parameter(Mandatory = $true)]
		[ValidateNotNull()]
		$Items,
		[Parameter(Mandatory = $false)]
		[string]
		$DisplayMember,
		[switch]
		$Append
	)
	
	if (-not $Append)
	{
		$ComboBox.Items.Clear()
	}
	
	if ($Items -is [Object[]])
	{
		$ComboBox.Items.AddRange($Items)
	}
	elseif ($Items -is [System.Collections.IEnumerable])
	{
		$ComboBox.BeginUpdate()
		foreach ($obj in $Items)
		{
			$ComboBox.Items.Add($obj)
		}
		$ComboBox.EndUpdate()
	}
	else
	{
		$ComboBox.Items.Add($Items)
	}
	
	$ComboBox.DisplayMember = $DisplayMember
}
#endregion

$BTN_Register_Click={
	#TODO: Place custom script here
	If (!(Test-Path "C:\ProgramData\OSDeploy"))
	{
		New-Item "C:\ProgramData\OSDeploy" -ItemType Directory -Force | Out-Null
	}
	$GrouptagVal = $CBX_GroupTag.Text
	$GrouptagVal | Out-File -FilePath "C:\ProgramData\OSDeploy\Grouptag.txt" -Encoding ascii -Force
	$Autopilot.Close()
	Invoke-WebPSScript "https://raw.githubusercontent.com/GregoryB74/OSD-Cloud/main/Get-WindowsAutoPilotInfo.ps1"
}
