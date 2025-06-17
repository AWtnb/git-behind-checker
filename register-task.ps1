$src = $PSScriptRoot | Join-Path -ChildPath "check-remote.ps1"
$action = New-ScheduledTaskAction -Execute powershell.exe -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$src`""
$settings = New-ScheduledTaskSettingsSet -Hidden -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

$startupTaskName = "git-remote-check_startup"
if ($null -ne (Get-ScheduledTask -TaskName $startupTaskName -ErrorAction SilentlyContinue)) {
    Unregister-ScheduledTask -TaskName $startupTaskName
}
Register-ScheduledTask -TaskName $startupTaskName `
    -Action $action `
    -Trigger $(New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME) `
    -Description "Run git remote branch checker on startup." `
    -Settings $settings

$dailyTaskName = "git-remote-check_daily"
if ($null -ne (Get-ScheduledTask -TaskName $dailyTaskName -ErrorAction SilentlyContinue)) {
    Unregister-ScheduledTask -TaskName $dailyTaskName
}
Register-ScheduledTask -TaskName $dailyTaskName `
    -Action $action `
    -Trigger $(New-ScheduledTaskTrigger -Daily -At "13:00") `
    -Description "Run git remote branch checker on 13:00." `
    -Settings $settings
