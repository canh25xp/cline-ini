param(
    [string]$VSCodeInstallerPath = "$PSScriptRoot\assets\VSCodeUserSetup.exe",
    [string]$VSCodeDownloadUrl = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user",
    [string]$ClineSRDownloadPath = "$PSScriptRoot\assets\cline-sr.cline-sr-1.8.0.vsix",
    [string]$ClineSRDownloadUrl = "https://ocean.sec.samsung.net/marketplace/api/cline-sr/cline-sr/1.8.0/file/cline-sr.cline-sr-1.8.0.vsix"
)

# Function to check if VSCode is installed
function Test-VSCodeInstalled {
    # Looks for user installed or system installed vscode
    $vscodePaths = @(
        "${env:LOCALAPPDATA}\Programs\Microsoft VS Code\Code.exe",
        "${env:ProgramFiles}\Microsoft VS Code\Code.exe",
        "${env:ProgramFiles(x86)}\Microsoft VS Code\Code.exe"
    )

    foreach ($path in $vscodePaths) {
        if (Test-Path $path) {
            $parent = Split-Path -Path $path -Parent
            Write-Debug "VSCode is already installed at: '$parent'"
            return $true
        }
    }

    $codePath = (Get-Command code.cmd -ErrorAction SilentlyContinue).Source
    if ($codePath) {
        $parent = Split-Path -Path $codePath -Parent
        $parent = Split-Path -Path $parent -Parent
        Write-Debug "VSCode is already installed at: '$parent' (found in PATH variable)"
        return $true
    }

    Write-Debug "VSCode not found"
    return $false
}

# Function to check if VSCode installer exists
function Test-VSCodeInstaller {
    param([string]$InstallerName)

    Write-Host "Checking if VSCode installer already exists..."
    if (Test-Path $InstallerName -PathType Leaf) {
        Write-Host "VSCode installer found: $InstallerName"
        return $true
    }

    Write-Host "VSCode installer not found"
    return $false
}

# Function to download VSCode installer
function Get-VSCodeInstaller {
    param([string]$Url, [string]$OutputFile)

    Write-Host "Downloading latest VSCode from: $Url"
    try {
        Invoke-WebRequest -Uri $Url -OutFile $OutputFile -UseBasicParsing
        Write-Host "VSCode download completed: $OutputFile"
    } catch {
        Write-Error "Failed to download VSCode: $_"
        exit 1
    }
}

# Function to install VSCode silently
function Install-VSCode {
    param([string]$InstallerPath)

    Write-Host "Installing VSCode ..."
    try {
        Start-Process -FilePath $InstallerPath -ArgumentList "/SILENT", "/MERGETASKS=!runcode,!desktopicon,!quicklaunchicon,!associatewithfiles,!addcontextmenufiles,!addcontextmenufolders,addtopath" -Wait
        # Merge tasks options
        # runcode                 Run VS Code after install
        # addtopath               Add `code` to PATH
        # desktopicon             Desktop shortcut
        # quicklaunchicon         Quick Launch / Taskbar shortcut
        # associatewithfiles      File associations
        # addcontextmenufiles     Open with Code on files
        # addcontextmenufolders   Open with Code on folders

        Write-Host "VSCode installation completed successfully"
    } catch {
        Write-Error "Failed to install VSCode: $_"
        exit 1
    }
}

# Function to download file if it doesn't exist
function Get-FileIfNotExists {
    param(
        [string]$Url,
        [string]$Destination
    )

    # Create directory if it doesn't exist
    $destinationDir = Split-Path -Path $Destination -Parent
    if (-not (Test-Path $destinationDir)) {
        New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
    }

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

# Function to check if VSCode extension is already installed
function Test-VSCodeExtensionInstalled {
    param(
        [string]$ExtensionPath
    )

    # Extract extension ID from VSIX filename (e.g., cline-sr.cline-sr-1.8.0.vsix -> cline-sr.cline-sr)
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($ExtensionPath)
    if ($fileName -match '^(.*)-\d+\.\d+\.\d+$') {
        $extensionId = $matches[1]
    } else {
        $extensionId = $fileName
    }

    Write-Debug "Checking if extension '$extensionId' is already installed..."
    try {
        $installedExtensions = & code --list-extensions 2>$null
        if ($installedExtensions -contains $extensionId) {
            Write-Host "Extension '$extensionId' is already installed"
            return $true
        } else {
            Write-Debug "Extension '$extensionId' is not installed"
            return $false
        }
    } catch {
        Write-Debug "Could not check installed extensions: $($_.Exception.Message)"
        return $false
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

    # Check if extension is already installed
    if (Test-VSCodeExtensionInstalled -ExtensionPath $ExtensionPath) {
        Write-Host "Skipping extension installation (already installed)"
        return
    }

    Write-Host "Installing VSCode extension from $ExtensionPath"
    try {
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
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

# Function to wait for key press or timeout
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

# Main installation process
Write-Host "=== Setup Start ==="

Write-Host "=== Installing VSCode ==="
if (Test-VSCodeInstalled) {
    Write-Host "VSCode is already installed."
} else {
    if (-not (Test-VSCodeInstaller -InstallerName $VSCodeInstallerPath)) {
        Get-VSCodeInstaller -Url $VSCodeDownloadUrl -OutputFile $VSCodeInstallerPath
    }
    Install-VSCode -InstallerPath $VSCodeInstallerPath
}
Write-Host "=== Installing VSCode Completed ==="


Write-Host "=== Installing ClineSR ==="
Get-FileIfNotExists -Url $ClineSRDownloadUrl -Destination $ClineSRDownloadPath
Install-VSCodeExtension -ExtensionPath $ClineSRDownloadPath
Write-Host "=== Installing ClineSR Completed ==="
Write-Host "=== Setup Completed ==="

Wait-ForKeyOrTimeout -TimeoutSeconds 5 -Prompt "Done. Press any key to continue..."
