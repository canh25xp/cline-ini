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

Write-Host "=== Installing VSCode ==="

if (Test-VSCodeInstalled) {
    Write-Host "VSCode is already installed."
    exit 0
}

# Latest vscode user setup for windows
$installerName = "$PSScriptRoot/assets/VSCodeUserSetup.exe"
$downloadUrl = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user"
# $downloadUrl = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64"

if (-not (Test-VSCodeInstaller -InstallerName $installerName)) {
    Get-VSCodeInstaller -Url $downloadUrl -OutputFile $installerName
}

Install-VSCode -InstallerPath $installerName

Write-Host "=== Installation Completed ==="
