# Skript na nastavenie prostredia pre Flutter vývoj
Write-Host "Nastavovanie prostredia pre Flutter..." -ForegroundColor Green

# Kontrola aktuálneho PATH
$currentPath = $env:PATH
Write-Host "Aktuálny PATH obsahuje:" -ForegroundColor Yellow
$currentPath -split ';' | Where-Object { $_ -like '*flutter*' -or $_ -like '*git*' } | ForEach-Object { Write-Host "  $_" -ForegroundColor Cyan }

# Kontrola Flutter
$flutterPath = "C:\flutter\bin"
if (Test-Path $flutterPath) {
    Write-Host "Flutter nájdený v: $flutterPath" -ForegroundColor Green
    if ($currentPath -notlike "*$flutterPath*") {
        Write-Host "Flutter nie je v PATH - pridávam..." -ForegroundColor Yellow
        $env:PATH += ";$flutterPath"
        Write-Host "Flutter pridaný do PATH pre túto reláciu" -ForegroundColor Green
    } else {
        Write-Host "Flutter už je v PATH" -ForegroundColor Green
    }
} else {
    Write-Host "Flutter nenájdený v $flutterPath" -ForegroundColor Red
}

# Kontrola Git
$gitPaths = @(
    "C:\Program Files\Git\bin",
    "C:\Program Files (x86)\Git\bin",
    "$env:USERPROFILE\AppData\Local\Programs\Git\bin"
)

$gitFound = $false
foreach ($gitPath in $gitPaths) {
    if (Test-Path $gitPath) {
        Write-Host "Git nájdený v: $gitPath" -ForegroundColor Green
        if ($currentPath -notlike "*$gitPath*") {
            Write-Host "Git nie je v PATH - pridávam..." -ForegroundColor Yellow
            $env:PATH += ";$gitPath"
            Write-Host "Git pridaný do PATH pre túto reláciu" -ForegroundColor Green
        } else {
            Write-Host "Git už je v PATH" -ForegroundColor Green
        }
        $gitFound = $true
        break
    }
}

if (-not $gitFound) {
    Write-Host "Git nenájdený! Nainštalujte Git z: https://git-scm.com/download/win" -ForegroundColor Red
}

# Test Flutter
Write-Host "`nTestovanie Flutter..." -ForegroundColor Yellow
try {
    if ($gitFound) {
        $flutterOutput = & "C:\flutter\bin\flutter.bat" doctor 2>&1
        Write-Host "Flutter doctor výstup:" -ForegroundColor Cyan
        $flutterOutput | ForEach-Object { Write-Host "  $_" }
    } else {
        Write-Host "Flutter test preskočený - Git nie je dostupný" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Chyba pri spustení Flutter: $($_.Exception.Message)" -ForegroundColor Red
}

# Inštrukcie pre trvalé nastavenie
Write-Host "`nPre trvalé nastavenie PATH:" -ForegroundColor Yellow
Write-Host "1. Otvorte Systémové nastavenia → Rozšírené nastavenia systému" -ForegroundColor White
Write-Host "2. Kliknite Premenné prostredia" -ForegroundColor White
Write-Host "3. V Systémových premenných nájdite Path" -ForegroundColor White
Write-Host "4. Pridajte tieto cesty:" -ForegroundColor White
Write-Host "   - $flutterPath" -ForegroundColor Cyan
if ($gitFound) {
    Write-Host "   - $gitPath" -ForegroundColor Cyan
}
Write-Host "5. Reštartujte PowerShell/Android Studio" -ForegroundColor White

Write-Host "`nSkript dokončený!" -ForegroundColor Green 