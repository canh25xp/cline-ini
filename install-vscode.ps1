function Test-VSCodeInstalled {
    Write-Debug "Checking VSCodeInstalled"

    $vscodePath     = "${env:ProgramFiles}\Microsoft VS Code\Code.exe"
    $vscodePathX86  = "${env:ProgramFiles(x86)}\Microsoft VS Code\Code.exe"
    $vscodePathUser = "${env:LOCALAPPDATA}\Programs\Microsoft VS Code\Code.exe"

    if (Test-Path $vscodePath -PathType Leaf) {
        Write-Debug "VSCode is already installed at: $vscodePath"
        return $true
    }

    if (Test-Path $vscodePathX86 -PathType Leaf) {
        Write-Debug "VSCode is already installed at: $vscodePathX86"
        return $true
    }

    if (Test-Path $vscodePathUser -PathType Leaf) {
        Write-Debug "VSCode is already installed at: $vscodePathUser"
        return $true
    }

    if (Get-Command code -ErrorAction SilentlyContinue) {
        Write-Debug "VSCode is already installed and available in PATH"
        return $true
    }

    Write-Debug "VSCode not found"
    return $false
}

function Test-VSCodeInstaller {
    param([string]$InstallerName)

    Write-Host "Checking if installer already exists..."
    if (Test-Path $InstallerName -PathType Leaf) {
        Write-Host "Installer found: $InstallerName"
        return $true
    }

    Write-Host "Installer not found"
    return $false
}

function Get-VSCodeInstaller {
    param([string]$Url, [string]$OutputFile)

    Write-Host "Downloading latest VSCode from: $Url"
    try {
        Invoke-WebRequest -Uri $Url -OutFile $OutputFile -UseBasicParsing
        Write-Host "Download completed: $OutputFile"
    } catch {
        Write-Error "Failed to download VSCode: $_"
        exit 1
    }
}

# Install VSCode silently
function Install-VSCode {
    param([string]$InstallerPath)

    Write-Host "Installing VSCode ..."
    try {
        Start-Process -FilePath $InstallerPath -ArgumentList "/SILENT", "/MERGETASKS=!runcode,!desktopicon,!quicklaunchicon,!associatewithfiles,!addcontextmenufiles,!addcontextmenufolders,!addtopath" -Wait
        Write-Host "VSCode installation completed successfully"
    } catch {
        Write-Error "Failed to install VSCode: $_"
        exit 1
    }
}

Write-Host "=== VSCode Installation Start ==="

if (Test-VSCodeInstalled) {
    Write-Host "VSCode is already installed."
    exit 0
}

# Latest vscode user setup for windows
$installerName = "VSCodeUserSetup.exe"
$downloadUrl = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user"
# $downloadUrl = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64"

if (-not (Test-VSCodeInstaller -InstallerName $installerName)) {
    Get-VSCodeInstaller -Url $downloadUrl -OutputFile $installerName
}

Install-VSCode -InstallerPath $installerName

Write-Host "=== Installation Process Completed ==="
