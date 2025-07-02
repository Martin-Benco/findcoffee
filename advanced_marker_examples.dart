import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';

/// Pokročilé príklady pre vlastné markery s cache-ovaním a optimalizáciou
class AdvancedMarkerManager {
  static final Map<String, BitmapDescriptor> _iconCache = {};
  
  /// Načíta a cache-uje vlastný marker
  static Future<BitmapDescriptor> getCachedMarker(String assetPath, {double size = 48}) async {
    final cacheKey = '${assetPath}_${size}';
    
    if (_iconCache.containsKey(cacheKey)) {
      return _iconCache[cacheKey]!;
    }
    
    try {
      final icon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(size, size)),
        assetPath,
      );
      _iconCache[cacheKey] = icon;
      return icon;
    } catch (e) {
      print('Chyba pri načítaní markeru $assetPath: $e');
      return BitmapDescriptor.defaultMarker;
    }
  }
  
  /// Vyčistí cache
  static void clearCache() {
    _iconCache.clear();
  }
  
  /// Načíta všetky potrebné markery vopred
  static Future<void> preloadMarkers() async {
    final markers = [
      'assets/icons/kavamark.png',
      // Pridajte ďalšie cesty k markerom podľa potreby
    ];
    
    for (final marker in markers) {
      await getCachedMarker(marker);
    }
  }
}

/// Trieda pre vytváranie markerov podľa rôznych kritérií
class SmartMarkerFactory {
  
  /// Vytvorí marker podľa hodnotenia kaviarne
  static Future<BitmapDescriptor> getRatingBasedMarker(double rating) async {
    if (rating >= 4.5) {
      return await AdvancedMarkerManager.getCachedMarker(
        'assets/icons/kavamark.png',
        size: 56, // Väčší marker pre vysoké hodnotenie
      );
    } else if (rating >= 4.0) {
      return await AdvancedMarkerManager.getCachedMarker(
        'assets/icons/kavamark.png',
        size: 48,
      );
    } else if (rating >= 3.0) {
      return await AdvancedMarkerManager.getCachedMarker(
        'assets/icons/kavamark.png',
        size: 40, // Menší marker pre nižšie hodnotenie
      );
    } else {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }
  
  /// Vytvorí marker podľa vzdialenosti
  static Future<BitmapDescriptor> getDistanceBasedMarker(double distanceKm) async {
    if (distanceKm <= 0.5) {
      return await AdvancedMarkerManager.getCachedMarker(
        'assets/icons/kavamark.png',
        size: 56, // Veľký marker pre blízke kaviarne
      );
    } else if (distanceKm <= 2.0) {
      return await AdvancedMarkerManager.getCachedMarker(
        'assets/icons/kavamark.png',
        size: 48,
      );
    } else if (distanceKm <= 5.0) {
      return await AdvancedMarkerManager.getCachedMarker(
        'assets/icons/kavamark.png',
        size: 40,
      );
    } else {
      return BitmapDescriptor.defaultMarkerWithHue(210.0); // približná šedá
    }
  }
  
  /// Vytvorí marker podľa typu kaviarne
  static Future<BitmapDescriptor> getTypeBasedMarker(String cafeType) async {
    switch (cafeType.toLowerCase()) {
      case 'coffee':
      case 'kaviareň':
        return await AdvancedMarkerManager.getCachedMarker('assets/icons/kavamark.png');
      case 'restaurant':
      case 'reštaurácia':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case 'cafe':
      case 'kaváreň':
        return await AdvancedMarkerManager.getCachedMarker('assets/icons/kavamark.png');
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }
  
  /// Vytvorí marker podľa kombinácie kritérií
  static Future<BitmapDescriptor> getSmartMarker({
    required double rating,
    required double distanceKm,
    String? cafeType,
  }) async {
    // Priorita 1: Vysoké hodnotenie
    if (rating >= 4.5) {
      return await AdvancedMarkerManager.getCachedMarker(
        'assets/icons/kavamark.png',
        size: 56,
      );
    }
    
    // Priorita 2: Blízka vzdialenosť
    if (distanceKm <= 0.5) {
      return await AdvancedMarkerManager.getCachedMarker(
        'assets/icons/kavamark.png',
        size: 52,
      );
    }
    
    // Priorita 3: Typ kaviarne
    if (cafeType != null) {
      return await getTypeBasedMarker(cafeType);
    }
    
    // Fallback
    return await AdvancedMarkerManager.getCachedMarker('assets/icons/kavamark.png');
  }
}

/// Widget pre demonštráciu pokročilých markerov
class AdvancedMarkerDemo extends StatefulWidget {
  const AdvancedMarkerDemo({super.key});

  @override
  State<AdvancedMarkerDemo> createState() => _AdvancedMarkerDemoState();
}

class _AdvancedMarkerDemoState extends State<AdvancedMarkerDemo> {
  Set<Marker> _markers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
  }

  Future<void> _initializeMarkers() async {
    // Preload všetkých markerov
    await AdvancedMarkerManager.preloadMarkers();
    
    // Vytvorenie testovacích markerov
    await _createDemoMarkers();
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _createDemoMarkers() async {
    final markers = <Marker>{};
    
    // Marker s vysokým hodnotením
    final highRatingIcon = await SmartMarkerFactory.getRatingBasedMarker(4.8);
    markers.add(Marker(
      markerId: const MarkerId('high_rating'),
      position: const LatLng(48.1486, 17.1077),
      icon: highRatingIcon,
      infoWindow: const InfoWindow(
        title: 'Vysoké hodnotenie',
        snippet: '4.8/5.0 - Veľký marker',
      ),
    ));
    
    // Marker s nízkym hodnotením
    final lowRatingIcon = await SmartMarkerFactory.getRatingBasedMarker(2.5);
    markers.add(Marker(
      markerId: const MarkerId('low_rating'),
      position: const LatLng(48.1486, 17.1078),
      icon: lowRatingIcon,
      infoWindow: const InfoWindow(
        title: 'Nízke hodnotenie',
        snippet: '2.5/5.0 - Červený marker',
      ),
    ));
    
    // Marker podľa vzdialenosti
    final distanceIcon = await SmartMarkerFactory.getDistanceBasedMarker(0.3);
    markers.add(Marker(
      markerId: const MarkerId('close_distance'),
      position: const LatLng(48.1486, 17.1076),
      icon: distanceIcon,
      infoWindow: const InfoWindow(
        title: 'Blízka kaviareň',
        snippet: '0.3 km - Veľký marker',
      ),
    ));
    
    // Smart marker
    final smartIcon = await SmartMarkerFactory.getSmartMarker(
      rating: 4.2,
      distanceKm: 1.5,
      cafeType: 'coffee',
    );
    markers.add(Marker(
      markerId: const MarkerId('smart_marker'),
      position: const LatLng(48.1487, 17.1077),
      icon: smartIcon,
      infoWindow: const InfoWindow(
        title: 'Smart Marker',
        snippet: 'Kombinácia kritérií',
      ),
    ));
    
    setState(() {
      _markers = markers;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Načítavam markery...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokročilé Markery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              AdvancedMarkerManager.clearCache();
              _initializeMarkers();
            },
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(48.1486, 17.1077),
          zoom: 15.0,
        ),
        markers: _markers,
      ),
    );
  }
}

/// Utility trieda pre prácu s markermi
class MarkerUtils {
  
  /// Skontroluje, či je marker viditeľný na mape
  static bool isMarkerVisible(LatLng markerPosition, LatLngBounds mapBounds) {
    return markerPosition.latitude >= mapBounds.southwest.latitude &&
           markerPosition.latitude <= mapBounds.northeast.latitude &&
           markerPosition.longitude >= mapBounds.southwest.longitude &&
           markerPosition.longitude <= mapBounds.northeast.longitude;
  }
  
  /// Vypočíta vzdialenosť medzi dvoma bodmi
  static double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // km
    
    final lat1 = point1.latitude * (pi / 180);
    final lat2 = point2.latitude * (pi / 180);
    final deltaLat = (point2.latitude - point1.latitude) * (pi / 180);
    final deltaLng = (point2.longitude - point1.longitude) * (pi / 180);
    
    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
              cos(lat1) * cos(lat2) *
              sin(deltaLng / 2) * sin(deltaLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  /// Filtruje markery podľa viditeľnosti
  static Set<Marker> filterVisibleMarkers(
    Set<Marker> allMarkers,
    LatLngBounds mapBounds,
  ) {
    return allMarkers.where((marker) {
      return isMarkerVisible(marker.position, mapBounds);
    }).toSet();
  }
} 