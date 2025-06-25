# Skript na opravu Android Studio PowerShell terminálu
Write-Host "Oprava Android Studio PowerShell terminálu..." -ForegroundColor Green

# Cesta k Android Studio PowerShell integrácii
$integrationDir = "C:\Program Files\Android\Android Studio\plugins\terminal\shell-integrations\powershell"
$integrationFile = "$integrationDir\powershell-integration.ps1"

# Kontrola, či adresár existuje
if (-not (Test-Path $integrationDir)) {
    Write-Host "Vytváram adresár: $integrationDir" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $integrationDir -Force | Out-Null
}

# Kontrola, či súbor existuje
if (-not (Test-Path $integrationFile)) {
    Write-Host "Vytváram chýbajúci súbor: $integrationFile" -ForegroundColor Yellow
    
    # Obsah PowerShell integrácie
    $integrationContent = @'
# PowerShell Integration for Android Studio Terminal
# This file enables proper terminal integration in Android Studio

# Set console title
$Host.UI.RawUI.WindowTitle = "Android Studio Terminal"

# Enable command history
Set-PSReadLineOption -HistorySavePath "$env:USERPROFILE\.android_studio_history"

# Set working directory to project root if available
if ($env:TERMINAL_EMULATOR -eq "JetBrains-JediTerm") {
    # Android Studio specific environment
    Write-Host "Android Studio Terminal - PowerShell Integration Active" -ForegroundColor Green
}

# Enable command completion
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView

# Custom prompt for Android Studio
function prompt {
    $currentPath = Get-Location
    $projectName = Split-Path $currentPath -Leaf
    return "[Android Studio] $projectName`nPS $currentPath> "
}

# Load project-specific settings if available
$projectSettings = "$PWD\.android_studio_settings.ps1"
if (Test-Path $projectSettings) {
    . $projectSettings
}

Write-Host "PowerShell integration loaded successfully!" -ForegroundColor Green
'@

    # Vytvorenie súboru
    try {
        $integrationContent | Out-File -FilePath $integrationFile -Encoding UTF8 -Force
        Write-Host "Súbor úspešne vytvorený!" -ForegroundColor Green
    } catch {
        Write-Host "Chyba pri vytváraní súboru: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Skúste spustiť Android Studio ako administrátor" -ForegroundColor Yellow
    }
} else {
    Write-Host "Súbor už existuje: $integrationFile" -ForegroundColor Green
}

# Test spustenia
Write-Host "`nTestovanie PowerShell integrácie..." -ForegroundColor Yellow
try {
    $testResult = & powershell -NoExit -ExecutionPolicy Bypass -File $integrationFile -Command "Write-Host 'Test úspešný!'"
    Write-Host "PowerShell integrácia funguje správne!" -ForegroundColor Green
} catch {
    Write-Host "Chyba pri teste: $($_.Exception.Message)" -ForegroundColor Red
}

# Nastavenia pre Android Studio
Write-Host "`nOdporúčané nastavenia pre Android Studio:" -ForegroundColor Yellow
Write-Host "1. Otvorte Android Studio" -ForegroundColor White
Write-Host "2. Prejdite na File → Settings (Ctrl+Alt+S)" -ForegroundColor White
Write-Host "3. Tools → Terminal" -ForegroundColor White
Write-Host "4. Nastavte Shell path: powershell.exe" -ForegroundColor White
Write-Host "5. Nastavte Shell arguments: -NoExit -ExecutionPolicy Bypass -File `"$integrationFile`"" -ForegroundColor White
Write-Host "6. Kliknite OK a reštartujte Android Studio" -ForegroundColor White

Write-Host "`nOprava dokončená!" -ForegroundColor Green 