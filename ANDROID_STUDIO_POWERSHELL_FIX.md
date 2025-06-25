# Oprava PowerShell problému v Android Studio

## Problém
Android Studio sa nepodarilo spustiť PowerShell terminál s chybou:
```
Failed to start [powershell.exe, -NoExit, -ExecutionPolicy, Bypass, -File, C:\Program Files\Android\Android Studio\plugins\terminal\shell-integrations\powershell\powershell-integration.ps1]
```

## Riešenie

### Krok 1: Nastavenie Android Studio
1. Otvorte **Android Studio**
2. Prejdite na **File** → **Settings** (Ctrl+Alt+S)
3. V ľavom menu vyberte **Tools** → **Terminal**
4. Nastavte tieto hodnoty:
   - **Shell path**: `C:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe`
   - **Shell arguments**: `-NoExit -ExecutionPolicy Bypass`
5. Kliknite **OK**
6. Reštartujte Android Studio

### Krok 2: Alternatívne riešenie (ak Krok 1 nefunguje)
Ak máte stále problémy, použite tieto nastavenia:
- **Shell path**: `C:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe`
- **Shell arguments**: `-NoExit -ExecutionPolicy Bypass -Command "Set-Location '$PWD'"`

### Krok 3: Testovanie
Po nastavení:
1. Otvorte terminál v Android Studio (**View** → **Tool Windows** → **Terminal**)
2. Mali by ste vidieť PowerShell prompt
3. Skontrolujte, či funguje: `Get-ExecutionPolicy`

### Krok 4: Flutter príkazy
Ak chcete používať Flutter v termináli:
```powershell
# Ak Flutter nie je v PATH, použite plnú cestu:
C:\flutter\bin\flutter.bat doctor
C:\flutter\bin\flutter.bat pub get
C:\flutter\bin\flutter.bat run
```

## Problémy s PSReadLine
Ak máte problémy s PSReadLine modulom (chyby pri písaní), môžete ho dočasne vypnúť:
```powershell
Remove-Module PSReadLine -Force
```

## Kontrola
Skontrolujte, či všetko funguje:
```powershell
$PSVersionTable.PSVersion
Get-ExecutionPolicy
Test-Path "C:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe"
```

## Poznámky
- Používajte vždy plnú cestu k PowerShell: `C:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe`
- Nepoužívajte integráciu, ak spôsobuje problémy
- Ak máte problémy s oprávneniami, spustite Android Studio ako administrátor 