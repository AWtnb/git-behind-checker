$config = Get-Content -Path $($PSScriptRoot | Join-Path -ChildPath "config.json") | ConvertFrom-Json

$taskPath = $config.taskPath
if (-not $taskPath.StartsWith("\")) {
    $taskPath = "\" + $taskPath
}
if (-not $taskPath.EndsWith("\")) {
    $taskPath = $taskPath + "\"
}

$appDir = $env:APPDATA | Join-Path -ChildPath $($PSScriptRoot | Split-Path -Leaf)
if (-not (Test-Path $appDir -PathType Container)) {
    New-Item -Path $appDir -ItemType Directory > $null
}
$src = $PSScriptRoot | Join-Path -ChildPath "check-remote.ps1" | Copy-Item -Destination $appDir -PassThru

$action = New-ScheduledTaskAction -Execute conhost.exe -Argument "--headless powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$src`""
$settings = New-ScheduledTaskSettingsSet -Hidden -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 30)

$startupTaskName = $config.TaskName.startup
$startupTrigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME

if ($null -ne (Get-ScheduledTask -TaskPath $taskPath -TaskName $startupTaskName -ErrorAction SilentlyContinue)) {
    Unregister-ScheduledTask -TaskPath $taskPath -TaskName $startupTaskName -Confirm:$false
}

Register-ScheduledTask -TaskName $startupTaskName `
    -TaskPath $taskPath `
    -Action $action `
    -Trigger $startupTrigger `
    -Description "Run git remote branch checker on startup." `
    -Settings $settings


$dailyTaskName = $config.taskName.daily
$dailyTrigger = New-ScheduledTaskTrigger -Daily -At "13:00"

if ($null -ne (Get-ScheduledTask -TaskPath $taskPath -TaskName $dailyTaskName -ErrorAction SilentlyContinue)) {
    Unregister-ScheduledTask -TaskPath $taskPath -TaskName $dailyTaskName -Confirm:$false
}

Register-ScheduledTask -TaskName $dailyTaskName `
    -TaskPath $taskPath `
    -Action $action `
    -Trigger $dailyTrigger `
    -Description "Run git remote branch checker on 13:00." `
    -Settings $settings
