# Testovací skript pre PowerShell
Write-Host "=== PowerShell Test ===" -ForegroundColor Green

# Test 1: Základné informácie
Write-Host "`n1. PowerShell verzia:" -ForegroundColor Yellow
$PSVersionTable.PSVersion

# Test 2: Execution Policy
Write-Host "`n2. Execution Policy:" -ForegroundColor Yellow
Get-ExecutionPolicy

# Test 3: Aktuálny adresár
Write-Host "`n3. Aktuálny adresár:" -ForegroundColor Yellow
Get-Location

# Test 4: Flutter dostupnosť
Write-Host "`n4. Flutter dostupnosť:" -ForegroundColor Yellow
if (Test-Path "C:\flutter\bin\flutter.bat") {
    Write-Host "Flutter nájdený: C:\flutter\bin\flutter.bat" -ForegroundColor Green
} else {
    Write-Host "Flutter nenájdený v C:\flutter\bin\flutter.bat" -ForegroundColor Red
}

# Test 5: Git dostupnosť
Write-Host "`n5. Git dostupnosť:" -ForegroundColor Yellow
try {
    $gitVersion = git --version 2>$null
    if ($gitVersion) {
        Write-Host "Git nájdený: $gitVersion" -ForegroundColor Green
    } else {
        Write-Host "Git nenájdený" -ForegroundColor Red
    }
} catch {
    Write-Host "Git nenájdený" -ForegroundColor Red
}

Write-Host "`n=== Test dokončený ===" -ForegroundColor Green 