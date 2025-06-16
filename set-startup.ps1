$wsShell = New-Object -ComObject WScript.Shell
$startup = $env:USERPROFILE | Join-Path -ChildPath "AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
$shortcutPath = $startup | Join-Path -ChildPath ("check-remote.lnk")
$shortcut = $wsShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $PSScriptRoot | Join-Path -ChildPath "check-remote.bat"
$shortcut.Save()
"Created shortcut on startup: {0}" -f $shortcutPath | Write-Host