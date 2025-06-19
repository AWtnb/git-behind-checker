# Not works on PowerShell 6+.
# https://qiita.com/relu/items/b7121487a1d5756dfcf9

$xml = @"
<toast scenario="incomingCall">
  <visual>
    <binding template="ToastGeneric">
      <text id="1"></text>
      <text id="2"></text>
    </binding>
  </visual>
</toast>
"@

function Invoke-Toast{
    param (
        [parameter(ValueFromPipeline = $true)][string]$message,
        [string]$title,
        [string]$emojiCodepoint = ""
    )
    if ($emojiCodepoint) {
        $title = $title + " " + [System.Char]::ConvertFromUtf32([System.Convert]::toInt32($emojiCodepoint, 16))
    }
    $xmlDoc = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]::New()
    $xmlDoc.loadXml($xml)
    $xmlDoc.selectSingleNode('//text[@id="1"]').InnerText = $title
    $xmlDoc.selectSingleNode('//text[@id="2"]').InnerText = $message
    $appId = "{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe"
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]::CreateToastNotifier($appId).Show($xmlDoc)
}


# Modify if necessary
$reposDir = $env:USERPROFILE | Join-Path -ChildPath "Personal\tools\repo"

if (-not (Test-Path $reposDir -PathType Container)) {
    "``{0}`` not found..." -f $reposDir | Invoke-Toast -title "ERROR!" -emojiCodepoint "1F525"
    exit 1
}

$behind = 0
$failed = 0

Get-ChildItem -Path $reposDir -Directory | ForEach-Object {
    $repoPath = $_.FullName
    $repoName = $_.Name

    if (Test-Path (Join-Path $repoPath ".git") -PathType Container) {
        Push-Location $repoPath
        try {
            git fetch --quiet 2>$null
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to fetch from remote."
            }
            $localBranch = git rev-parse --abbrev-ref HEAD
            $remoteTrackingBranch = git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>$null
            if ($null -eq $remoteTrackingBranch -or $LASTEXITCODE -ne 0) {
                throw "Cannot find remote tracking branch corresponds to {1}" -f $localBranch
            }
            $localCommit = git rev-parse $localBranch
            $remoteCommit = git rev-parse $remoteTrackingBranch
            if ($localCommit -ne $remoteCommit) {
                "Behind to remote branch ``{0}``" -f $remoteTrackingBranch | Invoke-Toast -title "``$repoName``" -emojiCodepoint "1F9F2"
                $behind += 1
            }
        }
        catch {
            $failed += 1
            Invoke-Toast -message $_ -title "ERROR! ``$repoName``" -emojiCodepoint "1F525"
        }
        finally {
            Pop-Location
        }
    }
}

if ($behind -lt 1 -and $failed -lt 1) {
    "Checked ``{0}``." -f $reposDir | Invoke-Toast -title "All repos are UP-TO-DATE!" -emojiCodepoint "1F38A"
}
