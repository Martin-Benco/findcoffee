# Vlastné PNG Markery pre Google Maps vo Flutteri

Tento súbor obsahuje inštrukcie a príklady pre implementáciu vlastných PNG markerov v Google Maps aplikácii.

## Konfigurácia

### 1. Pubspec.yaml
Uistite sa, že máte správne nakonfigurované assets v `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/icons/
    - assets/images/
```

### 2. Importy
Pridajte potrebné importy do vášho Dart súboru:

```dart
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
```

## Implementácia

### Základná implementácia

```dart
class _MapViewState extends State<_MapView> {
  BitmapDescriptor? _customMarkerIcon;

  @override
  void initState() {
    super.initState();
    _loadCustomMarkerIcon();
  }

  Future<void> _loadCustomMarkerIcon() async {
    try {
      _customMarkerIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/icons/kavMapIcon.png',
      );
      _updateMarkers();
    } catch (e) {
      print('Chyba pri načítaní vlastného marker ikony: $e');
      _customMarkerIcon = BitmapDescriptor.defaultMarker;
      _updateMarkers();
    }
  }

  void _updateMarkers() {
    setState(() {
      _markers = widget.cafes.map((cafe) {
        return Marker(
          markerId: MarkerId(cafe.id),
          position: LatLng(cafe.latitude, cafe.longitude),
          icon: _customMarkerIcon ?? BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(title: cafe.name),
        );
      }).toSet();
    });
  }
}
```

## Pokročilé možnosti

### 1. Rôzne veľkosti markerov

```dart
Future<BitmapDescriptor> loadCustomMarkerWithSize(double size) async {
  try {
    return await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(size, size)),
      'assets/icons/kavMapIcon.png',
    );
  } catch (e) {
    return BitmapDescriptor.defaultMarker;
  }
}
```

### 2. Markery podľa hodnotenia

```dart
BitmapDescriptor getRatingMarker(double rating) {
  if (rating >= 4.5) {
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.Hue.green);
  } else if (rating >= 4.0) {
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.Hue.yellow);
  } else if (rating >= 3.0) {
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.Hue.orange);
  } else {
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.Hue.red);
  }
}
```

### 3. Markery podľa vzdialenosti

```dart
BitmapDescriptor getDistanceMarker(double distanceKm) {
  if (distanceKm <= 1.0) {
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.Hue.green);
  } else if (distanceKm <= 3.0) {
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.Hue.yellow);
  } else if (distanceKm <= 5.0) {
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.Hue.orange);
  } else {
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.Hue.red);
  }
}
```

### 4. Markery z bytes (ak máte obrázok ako bytes)

```dart
Future<BitmapDescriptor> loadCustomMarkerFromBytes(Uint8List bytes) async {
  try {
    return BitmapDescriptor.fromBytes(bytes);
  } catch (e) {
    return BitmapDescriptor.defaultMarker;
  }
}
```

## Odporúčania pre PNG súbory

1. **Veľkosť**: Odporúčam 48x48 alebo 64x64 pixelov
2. **Formát**: PNG s transparentným pozadím
3. **Optimalizácia**: Použite komprimované PNG súbory
4. **Názov súboru**: Použite popisné názvy (napr. `coffee_marker.png`, `restaurant_marker.png`)

## Riešenie problémov

### Chyba: "Unable to load asset"
- Skontrolujte, či je cesta k súboru správna
- Uistite sa, že je súbor zahrnutý v `pubspec.yaml`
- Spustite `flutter clean` a `flutter pub get`

### Chyba: "ImageConfiguration size is required"
- Vždy špecifikujte `ImageConfiguration` s veľkosťou
- Použite `const ImageConfiguration(size: Size(48, 48))`

### Marker sa nezobrazuje
- Skontrolujte, či je `_customMarkerIcon` načítaný pred vytvorením markerov
- Pridajte fallback na `BitmapDescriptor.defaultMarker`

## Príklad použitia v aplikácii

```dart
// V _MapViewState
void _updateMarkers() {
  setState(() {
    _markers = widget.cafes.map((cafe) {
      return Marker(
        markerId: MarkerId(cafe.id),
        position: LatLng(cafe.latitude, cafe.longitude),
        icon: _customMarkerIcon ?? BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(
          title: cafe.name,
          snippet: 'Hodnotenie: ${cafe.rating}',
        ),
        onTap: () {
          // Akcia pri kliknutí na marker
          print('Kliknutie na kaviareň: ${cafe.name}');
        },
      );
    }).toSet();
  });
}
```

## Testovanie

Pre testovanie rôznych typov markerov môžete použiť `CustomMarkerTestWidget` z `custom_marker_examples.dart` súboru.

## Poznámky

- Vlastné markery sa načítavajú asynchrónne
- Vždy poskytnite fallback na štandardný marker
- Pre lepší výkon cache-ujte načítané ikony
- Testujte na rôznych zariadeniach a veľkostiach obrazovky 