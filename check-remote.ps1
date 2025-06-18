# Not works on PowerShell 6+.
# https://ascii.jp/elem/000/004/059/4059715/

function Invoke-Toast{
    param (
        [parameter(ValueFromPipeline = $true)][string]$message
    )
    $appId = "{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe"
    $template = [Windows.UI.Notifications.ToastNotificationManager,Windows.UI.Notifications, ContentType = WindowsRuntime]::GetTemplateContent(
        [Windows.UI.Notifications.ToastTemplateType, Windows.UI.Notifications, ContentType = WindowsRuntime]::ToastText01
    )
    $template.GetElementsByTagName("text").Item(0).InnerText=$message;
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($AppId).Show($template);
}

$toEmoji = [scriptblock]{
    param (
        [string]$codepoint
    )
    return [System.Char]::ConvertFromUtf32([System.Convert]::toInt32($codepoint, 16))
}

# Modify if necessary
$reposDir = $env:USERPROFILE | Join-Path -ChildPath "Personal\tools\repo"

if (-not (Test-Path $reposDir -PathType Container)) {
    "{0}ERROR:`nNot found: {1}" -f $toEmoji.InvokeReturnAsIs("1F525"), $reposDir | Invoke-Toast
    exit 1
}

$behind = 0

Get-ChildItem -Path $reposDir -Directory | ForEach-Object {
    $repoPath = $_.FullName
    $repoName = $_.Name

    $err = [scriptblock]{
        param(
            [string]$message
        )
        return "{0} {1} [git]:`nERROR! {2}" -f $toEmoji.InvokeReturnAsIs("1F525"), $repoName, $message
    }

    if (Test-Path (Join-Path $repoPath ".git") -PathType Container) {
        Push-Location $repoPath
        try {
            git fetch --quiet 2>$null
            if ($LASTEXITCODE -ne 0) {
                throw $err.InvokeReturnAsIs("Failed to fetch from remote.")
            }
            $localBranch = git rev-parse --abbrev-ref HEAD
            $remoteTrackingBranch = git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>$null
            if ($null -eq $remoteTrackingBranch -or $LASTEXITCODE -ne 0) {
                throw $err.InvokeReturnAsIs("Cannot find remote tracking branch corresponds to {1}" -f $localBranch)
            }
            $localCommit = git rev-parse $localBranch
            $remoteCommit = git rev-parse $remoteTrackingBranch
            if ($localCommit -ne $remoteCommit) {
                "{0} [git]:`nBehind to remote branch '{1}'" -f $toEmoji.InvokeReturnAsIs("1F9F2"), $repoName, $remoteTrackingBranch | Invoke-Toast
                $behind += 1
            }
        }
        catch {
            Invoke-Toast $_
        }
        finally {
            Pop-Location
        }
    }
}

if ($behind -lt 1) {
    "{0} [git]:`nAll repos within '{1}' is UP-TO-DATE!" -f $toEmoji.InvokeReturnAsIs("1F38A"), $reposDir | Invoke-Toast
}
