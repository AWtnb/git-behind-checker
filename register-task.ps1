$src = $PSScriptRoot | Join-Path -ChildPath "check-remote.ps1"
$action = New-ScheduledTaskAction -Execute conhost.exe -Argument "--headless powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$src`""
$settings = New-ScheduledTaskSettingsSet -Hidden -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

$startupTaskName = "git-remote-check_startup"
$startupTrigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$startupTrigger.Delay = [System.Xml.XmlConvert]::ToString((New-TimeSpan -Minutes 60))

if ($null -ne (Get-ScheduledTask -TaskName $startupTaskName -ErrorAction SilentlyContinue)) {
    Unregister-ScheduledTask -TaskName $startupTaskName -Confirm:$false
}

Register-ScheduledTask -TaskName $startupTaskName `
    -Action $action `
    -Trigger $startupTrigger `
    -Description "Run git remote branch checker on startup." `
    -Settings $settings


$dailyTaskName = "git-remote-check_daily"
$dailyTrigger = New-ScheduledTaskTrigger -Daily -At "13:00"

if ($null -ne (Get-ScheduledTask -TaskName $dailyTaskName -ErrorAction SilentlyContinue)) {
    Unregister-ScheduledTask -TaskName $dailyTaskName -Confirm:$false
}

Register-ScheduledTask -TaskName $dailyTaskName `
    -Action $action `
    -Trigger $dailyTrigger `
    -Description "Run git remote branch checker on 13:00." `
    -Settings $settings
