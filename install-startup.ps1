# Iron & Body Protocol — register Windows startup task
# Run once with: Right-click → "Run with PowerShell"

$taskName   = "IronBodyProtocol"
$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$nodePath   = (Get-Command node -ErrorAction Stop).Source

Write-Host "Project dir : $projectDir"
Write-Host "Node path   : $nodePath"

# Build dist/ if it doesn't exist
if (-not (Test-Path "$projectDir\dist\index.html")) {
    Write-Host "Building app..."
    Push-Location $projectDir
    npm run build
    Pop-Location
}

# Remove old task if it exists
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

$action  = New-ScheduledTaskAction `
    -Execute $nodePath `
    -Argument "server.js" `
    -WorkingDirectory $projectDir

$trigger = New-ScheduledTaskTrigger -AtLogOn

$settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit (New-TimeSpan -Hours 0) `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -StartWhenAvailable

# Run hidden — no console window
$principal = New-ScheduledTaskPrincipal `
    -UserId $env:USERNAME `
    -LogonType Interactive `
    -RunLevel Limited

Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Principal $principal `
    -Description "Starts the Iron & Body Protocol server on login" `
    -Force | Out-Null

Write-Host ""
Write-Host "Task '$taskName' registered. The server will start automatically on next login."
Write-Host "To start it now without rebooting, run:"
Write-Host "  Start-ScheduledTask -TaskName '$taskName'"
Write-Host ""
$start = Read-Host "Start the server now? (y/n)"
if ($start -eq 'y') {
    Start-ScheduledTask -TaskName $taskName
    Start-Sleep -Seconds 2
    Write-Host "Server started. Open http://localhost:3000"
}
