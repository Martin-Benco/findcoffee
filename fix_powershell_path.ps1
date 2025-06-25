# Oprava cesty k PowerShell v Android Studio
Write-Host "Oprava cesty k PowerShell v Android Studio..." -ForegroundColor Green

# Správna cesta k PowerShell
$powershellPath = "$env:SystemRoot\system32\WindowsPowerShell\v1.0\powershell.exe"

# Kontrola, či PowerShell existuje
if (Test-Path $powershellPath) {
    Write-Host "PowerShell nájdený: $powershellPath" -ForegroundColor Green
} else {
    Write-Host "PowerShell nenájdený!" -ForegroundColor Red
    exit 1
}

# Test spustenia PowerShell
Write-Host "`nTestovanie PowerShell..." -ForegroundColor Yellow
try {
    $testResult = & $powershellPath -Command "Write-Host 'PowerShell funguje!' -ForegroundColor Green"
    Write-Host "PowerShell test úspešný!" -ForegroundColor Green
} catch {
    Write-Host "Chyba pri teste PowerShell: $($_.Exception.Message)" -ForegroundColor Red
}

# Odporúčané nastavenia pre Android Studio
Write-Host "`nOdporúčané nastavenia pre Android Studio:" -ForegroundColor Yellow
Write-Host "1. Otvorte Android Studio" -ForegroundColor White
Write-Host "2. Prejdite na File → Settings (Ctrl+Alt+S)" -ForegroundColor White
Write-Host "3. Tools → Terminal" -ForegroundColor White
Write-Host "4. Nastavte Shell path: $powershellPath" -ForegroundColor White
Write-Host "5. Nastavte Shell arguments: -NoExit -ExecutionPolicy Bypass" -ForegroundColor White
Write-Host "6. Kliknite OK a reštartujte Android Studio" -ForegroundColor White

# Alternatívne riešenie - bez integrácie
Write-Host "`nAlternatívne riešenie (bez integrácie):" -ForegroundColor Cyan
Write-Host "Shell path: $powershellPath" -ForegroundColor White
Write-Host "Shell arguments: -NoExit -ExecutionPolicy Bypass -Command `"Set-Location '$PWD'`"" -ForegroundColor White

Write-Host "`nOprava dokončená!" -ForegroundColor Green 