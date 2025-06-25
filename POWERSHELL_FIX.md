# Riešenie PowerShell problému v Android Studio

## Problém
Android Studio sa nepodarilo spustiť PowerShell terminál s chybou:
```
Failed to start [powershell.exe, -NoExit, -ExecutionPolicy, Bypass, -File, C:\Program Files\Android\Android Studio\plugins\terminal\shell-integrations\powershell\powershell-integration.ps1]
```

## Diagnóza
✅ PowerShell verzia: 5.1.26100.4202  
✅ Execution Policy: RemoteSigned  
✅ PowerShell integrácia existuje a je funkčná  
❌ Git nie je v PATH (Flutter vyžaduje Git)  
❌ Flutter nie je v PATH  

## Riešenia

### Riešenie 1: Resetovanie Android Studio nastavení
1. Zatvorte Android Studio
2. Otvorte Android Studio
3. Prejdite na **File** → **Settings** (Ctrl+Alt+S)
4. **Tools** → **Terminal**
5. Nastavte:
   - **Shell path**: `powershell.exe`
   - **Shell arguments**: `-NoExit -ExecutionPolicy Bypass`

### Riešenie 2: Manuálne spustenie PowerShell
Ak Android Studio stále nefunguje, môžete spustiť PowerShell manuálne:
```powershell
powershell -NoExit -ExecutionPolicy Bypass
```

### Riešenie 3: Vytvorenie vlastného terminálu
1. V Android Studio: **View** → **Tool Windows** → **Terminal**
2. Kliknite na **+** a vyberte **PowerShell**
3. Ak sa nezobrazí, vyberte **Command Prompt** a potom manuálne spustite PowerShell

### Riešenie 4: Kontrola oprávnení
Spustite Android Studio ako administrátor:
1. Kliknite pravým tlačidlom na Android Studio
2. Vyberte **Spustiť ako správca**

### Riešenie 5: Aktualizácia Android Studio
1. **Help** → **Check for Updates**
2. Nainštalujte najnovšiu verziu

### Riešenie 6: Pridanie Flutter a Git do PATH
1. Otvorte **Systémové nastavenia** → **Rozšírené nastavenia systému**
2. Kliknite **Premenné prostredia**
3. V sekcii **Systémové premenné** nájdite **Path**
4. Pridajte tieto cesty:
   - `C:\flutter\bin`
   - `C:\Program Files\Git\bin` (ak je Git nainštalovaný)
5. Reštartujte PowerShell/Android Studio

### Riešenie 7: Inštalácia Git
Ak Git nie je nainštalovaný:
1. Stiahnite Git z: https://git-scm.com/download/win
2. Nainštalujte s predvolenými nastaveniami
3. Reštartujte systém

## Testovanie
Po aplikovaní riešení skontrolujte:
```powershell
Get-ExecutionPolicy
$PSVersionTable.PSVersion
Test-Path "C:\Program Files\Android\Android Studio\plugins\terminal\shell-integrations\powershell\powershell-integration.ps1"
git --version
flutter doctor
```

## Flutter príkazy
Keďže máte Flutter projekt, môžete testovať:
```powershell
# Ak Flutter nie je v PATH, použite plnú cestu:
C:\flutter\bin\flutter.bat doctor
C:\flutter\bin\flutter.bat pub get
C:\flutter\bin\flutter.bat run
```

## Aktuálny stav
- ✅ PowerShell funguje správne
- ❌ Git nie je v PATH (vyžaduje sa pre Flutter)
- ❌ Flutter nie je v PATH (ale je nainštalovaný v C:\flutter\bin\)

## Kontakt
Ak problém pretrváva, skontrolujte:
- Logy Android Studio (Help → Show Log)
- Windows Event Viewer
- PowerShell Execution Policy nastavenia
- Git inštaláciu a PATH nastavenia 