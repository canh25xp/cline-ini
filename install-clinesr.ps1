param(
    [string]$DownloadPath = "$env:TEMP\cline-sr.cline-sr-1.8.0.vsix",
    [string]$DownloadUrl = "https://ocean.sec.samsung.net/marketplace/api/cline-sr/cline-sr/1.8.0/file/cline-sr.cline-sr-1.8.0.vsix"
)

# Function to download file if it doesn't exist
function Get-FileIfNotExists {
    param(
        [string]$Url,
        [string]$Destination
    )

    if (Test-Path $Destination) {
        Write-Host "File already exists at $Destination"
        return
    }

    Write-Host "Downloading from $Url"
    try {
        Invoke-WebRequest -Uri $Url -OutFile $Destination -ErrorAction Stop
        Write-Host "Download completed successfully"
    } catch {
        Write-Error "Failed to download file: $($_.Exception.Message)"
        exit 1
    }
}

# Function to install VSCode extension
function Install-VSCodeExtension {
    param(
        [string]$ExtensionPath
    )

    if (-not (Test-Path $ExtensionPath)) {
        Write-Error "Extension file not found: $ExtensionPath"
        exit 1
    }

    Write-Host "Installing VSCode extension from $ExtensionPath"
    try {
        & code --install-extension $ExtensionPath
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Extension installed successfully"
        } else {
            Write-Error "Failed to install extension, exit code: $LASTEXITCODE"
            exit 1
        }
    } catch {
        Write-Error "Failed to install extension: $($_.Exception.Message)"
        exit 1
    }
}

Write-Host "=== Installing ClineSR ==="

Get-FileIfNotExists -Url $DownloadUrl -Destination $DownloadPath

Install-VSCodeExtension -ExtensionPath $DownloadPath

Write-Host "=== Installation Completed ==="
