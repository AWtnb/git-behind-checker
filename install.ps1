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
$PSScriptRoot | Join-Path -ChildPath "update-repos.ps1" | Copy-Item -Destination $appDir

$checkDir = $env:USERPROFILE | Join-Path -ChildPath "Personal\tools\repo"
if (($args.Count -gt 0) -and ($args[0].Trim().Length -gt 0)) {
    $checkDir = $args[0].Trim()
}

$action = New-ScheduledTaskAction -Execute powershell.exe -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$src`" `"$checkDir`""
$baseSettingParams = @{
    Hidden                     = $true;
    AllowStartIfOnBatteries    = $true;
    DontStopIfGoingOnBatteries = $true;
    RunOnlyIfNetworkAvailable  = $true;
    RestartCount               = 2;
    RestartInterval            = (New-TimeSpan -Minutes 5);
}

$startupTaskName = $config.TaskName.startup
$startupTrigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$startupTrigger.Delay = [System.Xml.XmlConvert]::ToString((New-TimeSpan -Seconds 30))
$startupSettingParam = $baseSettingParams.Clone()
$startupSettingParam["StartWhenAvailable"] = $true
$startupSetting = New-ScheduledTaskSettingsSet @startupSettingParam

Register-ScheduledTask -TaskName $startupTaskName `
    -TaskPath $taskPath `
    -Action $action `
    -Trigger $startupTrigger `
    -Description "Run git remote branch checker on startup." `
    -Settings $startupSetting `
    -Force

$dailyTaskName = $config.taskName.daily
$dailyTrigger = New-ScheduledTaskTrigger -Daily -At "13:00"
$dailySetting = New-ScheduledTaskSettingsSet @baseSettingParams

Register-ScheduledTask -TaskName $dailyTaskName `
    -TaskPath $taskPath `
    -Action $action `
    -Trigger $dailyTrigger `
    -Description "Run git remote branch checker on 13:00." `
    -Settings $dailySetting `
    -Force
