import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Príklady rôznych spôsobov implementácie vlastných markerov
class CustomMarkerExamples {
  
  /// Príklad 1: Základný vlastný marker z PNG súboru
  static Future<BitmapDescriptor> loadCustomMarkerFromPNG() async {
    try {
      return await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/icons/kavamark.png',
      );
    } catch (e) {
      print('Chyba pri načítaní PNG markeru: $e');
      return BitmapDescriptor.defaultMarker;
    }
  }

  /// Príklad 2: Vlastný marker s rôznymi veľkosťami
  static Future<BitmapDescriptor> loadCustomMarkerWithSize(double size) async {
    try {
      return await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(size, size)),
        'assets/icons/kavamark.png',
      );
    } catch (e) {
      print('Chyba pri načítaní markeru s veľkosťou $size: $e');
      return BitmapDescriptor.defaultMarker;
    }
  }

  /// Príklad 3: Vlastný marker s rôznymi farbami (používa štandardný marker s farbou)
  static BitmapDescriptor getColoredMarker(double hue) {
    return BitmapDescriptor.defaultMarkerWithHue(hue);
  }

  /// Príklad 4: Vlastný marker z bytes (ak máš obrázok ako bytes)
  static Future<BitmapDescriptor> loadCustomMarkerFromBytes(Uint8List bytes) async {
    try {
      return BitmapDescriptor.fromBytes(bytes);
    } catch (e) {
      print('Chyba pri načítaní markeru z bytes: $e');
      return BitmapDescriptor.defaultMarker;
    }
  }

  /// Príklad 5: Vlastný marker s rôznymi ikonami pre rôzne typy kaviarní
  static Future<BitmapDescriptor> getCafeTypeMarker(String cafeType) async {
    String iconPath;
    
    switch (cafeType.toLowerCase()) {
      case 'coffee':
        iconPath = 'assets/icons/kavamark.png';
        break;
      case 'restaurant':
        iconPath = 'assets/icons/restaurant_icon.png';
        break;
      case 'cafe':
        iconPath = 'assets/icons/cafe_icon.png';
        break;
      default:
        iconPath = 'assets/icons/kavamark.png';
    }

    try {
      return await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        iconPath,
      );
    } catch (e) {
      print('Chyba pri načítaní markeru pre typ $cafeType: $e');
      return BitmapDescriptor.defaultMarker;
    }
  }

  /// Príklad 6: Vlastný marker s rôznymi farbami podľa hodnotenia
  static BitmapDescriptor getRatingMarker(double rating) {
    if (rating >= 4.5) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    } else if (rating >= 4.0) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
    } else if (rating >= 3.0) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    } else {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  /// Príklad 7: Vlastný marker s rôznymi farbami podľa vzdialenosti
  static BitmapDescriptor getDistanceMarker(double distanceKm) {
    if (distanceKm <= 1.0) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    } else if (distanceKm <= 3.0) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
    } else if (distanceKm <= 5.0) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    } else {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }
}

/// Widget pre testovanie rôznych typov markerov
class CustomMarkerTestWidget extends StatefulWidget {
  const CustomMarkerTestWidget({super.key});

  @override
  State<CustomMarkerTestWidget> createState() => _CustomMarkerTestWidgetState();
}

class _CustomMarkerTestWidgetState extends State<CustomMarkerTestWidget> {
  Set<Marker> _markers = {};
  BitmapDescriptor? _customIcon;

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
  }

  Future<void> _loadCustomMarker() async {
    final icon = await CustomMarkerExamples.loadCustomMarkerFromPNG();
    setState(() {
      _customIcon = icon;
      _createTestMarkers();
    });
  }

  void _createTestMarkers() {
    if (_customIcon == null) return;

    setState(() {
      _markers = {
        // Vlastný PNG marker
        Marker(
          markerId: const MarkerId('custom_png'),
          position: const LatLng(48.1486, 17.1077),
          icon: _customIcon!,
          infoWindow: const InfoWindow(title: 'Vlastný PNG Marker'),
        ),
        
        // Zelený marker pre vysoké hodnotenie
        Marker(
          markerId: const MarkerId('high_rating'),
          position: const LatLng(48.1486, 17.1078),
          icon: CustomMarkerExamples.getRatingMarker(4.8),
          infoWindow: const InfoWindow(title: 'Vysoké hodnotenie (4.8)'),
        ),
        
        // Červený marker pre nízke hodnotenie
        Marker(
          markerId: const MarkerId('low_rating'),
          position: const LatLng(48.1486, 17.1076),
          icon: CustomMarkerExamples.getRatingMarker(2.5),
          infoWindow: const InfoWindow(title: 'Nízke hodnotenie (2.5)'),
        ),
        
        // Marker podľa vzdialenosti
        Marker(
          markerId: const MarkerId('distance'),
          position: const LatLng(48.1487, 17.1077),
          icon: CustomMarkerExamples.getDistanceMarker(0.5),
          infoWindow: const InfoWindow(title: 'Blízka kaviareň (0.5 km)'),
        ),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(48.1486, 17.1077),
        zoom: 15.0,
      ),
      markers: _markers,
    );
  }
} 