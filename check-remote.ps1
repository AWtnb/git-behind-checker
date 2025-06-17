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

# Modify if necessary
$reposDir = $env:USERPROFILE | Join-Path -ChildPath "Personal\tools\repo"

if (-not (Test-Path $reposDir -PathType Container)) {
    "ERROR:`nNot found: {0}" -f $reposDir | Invoke-Toast
    exit 1
}


Get-ChildItem -Path $reposDir -Directory | ForEach-Object {
    $repoPath = $_.FullName
    $repoName = $_.Name

    $err = [scriptblock]{
        param(
            [string]$message
        )
        return "[git] {0}:`nERROR! {1}" -f $repoName, $message
    }

    if (Test-Path (Join-Path $repoPath ".git") -PathType Container) {
        Push-Location $repoPath
        try {
            git fetch --quiet 2>$null
            if ($LASTEXITCODE -ne 0) {
                throw $err.Invoke("Failed to fetch from remote.")
            }
            $localBranch = git rev-parse --abbrev-ref HEAD
            $remoteTrackingBranch = git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>$null
            if ($null -eq $remoteTrackingBranch -or $LASTEXITCODE -ne 0) {
                throw $err.Invoke("Cannot find remote tracking branch corresponds to {1}" -f $localBranch)
            }
            $localCommit = git rev-parse $localBranch
            $remoteCommit = git rev-parse $remoteTrackingBranch
            if ($localCommit -ne $remoteCommit) {
                "[git] {0}:`nBehind to remote branch '{1}'" -f $repoName, $remoteTrackingBranch | Invoke-Toast
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
