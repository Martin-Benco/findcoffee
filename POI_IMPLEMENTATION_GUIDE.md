# Implementácia POI Filtrovania v Google Maps

## Prehľad
Tento dokument vysvetľuje, ako sme implementovali filtrovanie POI (Points of Interest) v Google Maps, aby sme skryli iba kaviarne a reštaurácie, zatiaľ čo ostatné POI zostali viditeľné pre lepšiu orientáciu používateľov.

## Čo sme zmenili

### 1. Mapový štýl (assets/map_style.json)
Odstránili sme všeobecné skrývanie všetkých POI a nahradili ho špecifickým filtrom:

**Pred (všetky POI skryté):**
```json
{
  "featureType": "poi",
  "elementType": "all",
  "stylers": [
    {
      "visibility": "off"
    }
  ]
}
```

**Po (iba kaviarne a reštaurácie skryté):**
```json
{
  "featureType": "poi.cafe",
  "elementType": "all",
  "stylers": [
    {
      "visibility": "off"
    }
  ]
},
{
  "featureType": "poi.restaurant",
  "elementType": "all",
  "stylers": [
    {
      "visibility": "off"
    }
  ]
}
```

### 2. Výsledok
- ✅ **Kaviarne a reštaurácie** - skryté (nekonkurujú našim vlastným markerom)
- ✅ **Pamiatky, stanice, úrady, parky** - viditeľné (pomáhajú pri orientácii)
- ✅ **Vlastné markery kaviarní** - stále viditeľné a funkčné

## Ako to funguje

### Mapový štýl JSON
Mapový štýl sa načíta z `assets/map_style.json` a aplikuje sa na GoogleMap widget:

```dart
Future<void> _loadMapStyle() async {
  try {
    final styleString = await rootBundle.loadString('assets/map_style.json');
    setState(() {
      _mapStyle = styleString;
    });
  } catch (e) {
    print('Chyba pri načítaní mapového štýlu: $e');
  }
}
```

### Aplikovanie štýlu
Štýl sa aplikuje v `onMapCreated` callback:

```dart
onMapCreated: (GoogleMapController controller) {
  _mapController = controller;
  
  // Aplikovanie mapového štýlu
  if (_mapStyle != null) {
    controller.setMapStyle(_mapStyle!);
  }
  // ...
}
```

## Alternatívne riešenie - Štýl priamo v kóde

Ak chcete mať mapový štýl priamo v kóde namiesto JSON súboru, môžete použiť metódu `_getMapStyleString()` v `lib/main.dart`:

```dart
String _getMapStyleString() {
  return '''
[
  {
    "featureType": "poi.cafe",
    "elementType": "all",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi.restaurant",
    "elementType": "all",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  }
  // ... ďalšie štýly
]
''';
}
```

A potom ju použiť namiesto načítania z JSON:

```dart
// Namiesto _loadMapStyle() použite:
setState(() {
  _mapStyle = _getMapStyleString();
});
```

## Úprava štýlu cez Google Map Style Wizard

1. Choďte na https://mapstyle.withgoogle.com
2. Vytvorte nový štýl alebo importujte existujúci
3. V sekcii "POI" nastavte:
   - **Cafes** → Hide
   - **Restaurants** → Hide
   - **All other POI types** → Show
4. Exportujte JSON a nahraďte obsah `assets/map_style.json`

## Testovanie

Pre testovanie zmen v mapovom štýle:

1. **Skrytie kaviarní a reštaurácií:**
   - Hľadajte na mape kaviarne a reštaurácie - mali by byť skryté
   - Vaše vlastné markery by mali zostať viditeľné

2. **Viditeľnosť ostatných POI:**
   - Pamiatky, stanice, úrady, parky by mali byť viditeľné
   - Tieto POI pomáhajú používateľom pri orientácii

3. **Funkčnosť vlastných markerov:**
   - Kliknutie na vaše markery by malo otvoriť detail kaviarne
   - Vlastné markery by mali mať správnu ikonu a veľkosť

## Príklady POI typov, ktoré zostávajú viditeľné

- `poi.attraction` - turistické atrakcie
- `poi.government` - úrady a inštitúcie
- `poi.medical` - nemocnice a zdravotnícke zariadenia
- `poi.park` - parky a zelené plochy
- `poi.place_of_worship` - kostoly a náboženské budovy
- `poi.school` - školy a vzdelávacie inštitúcie
- `poi.sports_complex` - športové areály
- `transit.station` - stanice MHD, vlakové stanice
- `transit.station.bus` - autobusové zastávky
- `transit.station.rail` - vlakové stanice

## Riešenie problémov

### POI stále viditeľné
1. Skontrolujte, či sa mapový štýl správne načítal
2. Overte, či sa aplikoval v `onMapCreated`
3. Skúste vyčistiť cache aplikácie

### Vlastné markery nefungujú
1. Skontrolujte, či sú markery správne vytvorené
2. Overte, či sú správne nastavené callback funkcie
3. Skontrolujte konzolu pre chybové hlásenia

### Výkon
1. Mapový štýl sa načítava len raz pri inicializácii
2. JSON súbor je malý a neovplyvňuje výkon
3. Ak máte problémy s výkonom, zvážte použitie štýlu priamo v kóde

## Ďalšie možnosti

### Dynamické filtrovanie
Môžete implementovať prepínač pre zobrazenie/skrytie POI:

```dart
bool _showPOI = true;

// V mapovom štýle podmienene skryť POI
if (!_showPOI) {
  // Pridať pravidlo pre skrývanie všetkých POI
}
```

### Filtrovanie podľa vzdialenosti
Môžete skryť POI, ktoré sú príliš ďaleko od používateľa:

```dart
// V mapovom štýle pridať pravidlo pre skrývanie vzdialených POI
{
  "featureType": "poi",
  "elementType": "all",
  "stylers": [
    {
      "visibility": "simplified" // Zjednodušené zobrazenie pre vzdialené POI
    }
  ]
}
```

## Záver

Táto implementácia umožňuje:
- Skryť konkurenčné kaviarne a reštaurácie
- Zachovať orientačné POI pre lepšiu používateľskú skúsenosť
- Flexibilitu pri úprave štýlu cez Google Map Style Wizard
- Jednoduchú údržbu a testovanie 