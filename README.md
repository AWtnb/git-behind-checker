# README

This Windows PowerShell script automatically checks each Git repository within a specified root directory and notifies you with a Windows toast notification if there are updates on the remote repository.

### Modify `check-remote.ps1` if necessary

```PowerShell
$reposDir = $env:USERPROFILE | Join-Path -ChildPath "Personal\tools\repo" # Example
```

For instance, if your repositories are in C:\Users\YourUsername\Documents\GitHub, change it to:

```PowerShell
$reposDir = "C:\Users\YourUsername\Documents\GitHub".
```

## Install

[register-task.ps1](./register-task.ps1) copies [check-remote.ps1](./check-remote.ps1) to `$env:AppData\Roaming\git-status-toast` and registers scheduled task to run it on logon and 13:00.

## Notes

- Git Installation: Git must be installed on the system running the script, and the git command should be accessible from the command prompt or PowerShell.
- PowerShell Version: The toast notification function (`Invoke-Toast`) in this script might not work on PowerShell 6.0+ due to changes in how Universal Windows Platform (UWP) APIs are called. It should work without issues on PowerShell 5.1 (which is typically pre-installed on Windows).
