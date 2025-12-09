# VSCode + ClineSR installation script

## Objective

- Automatically installing VSCode with ClineSR extension ready.
- Minimize user interaction during installing process.
- Minimize internet access during installation (offline installation)
- BONUS: auto setup Cline API keys.

## Method

- Single powershell setup script.
- Shipping `assets` (installers and extensions) with the setup script.

## TODO

- [x] Merge `./install-clinesr.ps1` and `./install-vscode.ps1` into a single script.
- [ ] Script that generate archive including the final script and all the require installers.
- [ ] Download latest version of ClineSR instead of hard-coding.
- [x] Reload PATH environment variable after installation.
- [ ] Setup Cline API keys programmatically.
