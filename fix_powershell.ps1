# Skript na opravu PowerShell problémov v Android Studio
Write-Host "Kontrola PowerShell nastavení..." -ForegroundColor Green

# Kontrola Execution Policy
$policy = Get-ExecutionPolicy
Write-Host "Aktuálna Execution Policy: $policy" -ForegroundColor Yellow

if ($policy -eq "Restricted") {
    Write-Host "Nastavujem Execution Policy na RemoteSigned..." -ForegroundColor Yellow
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Write-Host "Execution Policy nastavená na RemoteSigned" -ForegroundColor Green
}

# Kontrola PowerShell verzie
$psVersion = $PSVersionTable.PSVersion
Write-Host "PowerShell verzia: $psVersion" -ForegroundColor Yellow

# Kontrola cesty k Android Studio PowerShell integrácii
$integrationPath = "C:\Program Files\Android\Android Studio\plugins\terminal\shell-integrations\powershell\powershell-integration.ps1"
if (Test-Path $integrationPath) {
    Write-Host "PowerShell integrácia nájdená: $integrationPath" -ForegroundColor Green
} else {
    Write-Host "PowerShell integrácia nenájdená!" -ForegroundColor Red
}

# Test spustenia PowerShell integrácie
Write-Host "Testovanie spustenia PowerShell integrácie..." -ForegroundColor Yellow
try {
    & powershell -NoExit -ExecutionPolicy Bypass -File $integrationPath
    Write-Host "PowerShell integrácia úspešne spustená!" -ForegroundColor Green
} catch {
    Write-Host "Chyba pri spustení PowerShell integrácie: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "Skript dokončený." -ForegroundColor Green 