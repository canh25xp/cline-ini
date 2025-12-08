# TODO : Merge `./install-clinesr.ps1` and `./install-vscode.ps1` into a single script.

function Wait-ForKeyOrTimeout {
    param(
        [int]$TimeoutSeconds = 10,
        [string]$Prompt = "Press any key to continue, or wait for timeout..."
    )

    Write-Host $Prompt

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $keyDetected = $false

    while ($stopwatch.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
        if ([Console]::KeyAvailable) {
            $Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown") | Out-Null # Consume the keypress
            $keyDetected = $true
            break
        }
        Start-Sleep -Milliseconds 50 # Prevent excessive CPU usage
    }

    if ($keyDetected) {
        Write-Debug "Key pressed. Continuing..."
    } else {
        Write-Debug "Timeout reached. Continuing..."
    }
}

Wait-ForKeyOrTimeout -TimeoutSeconds 5 -Prompt "Done. Press any key to continue..."
