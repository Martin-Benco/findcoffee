import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Utility trieda pre prácu s veľkosťami markerov
class MarkerSizeUtility {
  
  /// Štandardné veľkosti markerov
  static const Map<String, Size> standardSizes = {
    'small': Size(32, 32),
    'medium': Size(48, 48),
    'large': Size(64, 64),
    'xlarge': Size(80, 80),
    'xxlarge': Size(96, 96),
    'xxxlarge': Size(120, 120),
  };
  
  /// Načíta marker s konkrétnou veľkosťou
  static Future<BitmapDescriptor> loadMarkerWithSize(
    String assetPath, 
    Size size,
  ) async {
    try {
      return await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: size),
        assetPath,
      );
    } catch (e) {
      print('Chyba pri načítaní markeru s veľkosťou ${size.width}x${size.height}: $e');
      return BitmapDescriptor.defaultMarker;
    }
  }
  
  /// Načíta marker s preddefinovanou veľkosťou
  static Future<BitmapDescriptor> loadMarkerWithPresetSize(
    String assetPath, 
    String sizeName,
  ) async {
    final size = standardSizes[sizeName] ?? standardSizes['medium']!;
    return await loadMarkerWithSize(assetPath, size);
  }
  
  /// Testovacia metóda - načíta všetky veľkosti pre porovnanie
  static Future<Map<String, BitmapDescriptor>> loadAllSizes(String assetPath) async {
    final Map<String, BitmapDescriptor> markers = {};
    
    for (final entry in standardSizes.entries) {
      markers[entry.key] = await loadMarkerWithSize(assetPath, entry.value);
    }
    
    return markers;
  }
  
  /// Odporúčané veľkosti pre rôzne použitia
  static const Map<String, Size> recommendedSizes = {
    'mobile_small': Size(40, 40),    // Pre mobilné zariadenia, kompaktný vzhľad
    'mobile_medium': Size(56, 56),   // Pre mobilné zariadenia, štandardný vzhľad
    'mobile_large': Size(72, 72),    // Pre mobilné zariadenia, výrazný vzhľad
    'tablet_small': Size(48, 48),    // Pre tablety, kompaktný vzhľad
    'tablet_medium': Size(64, 64),   // Pre tablety, štandardný vzhľad
    'tablet_large': Size(80, 80),    // Pre tablety, výrazný vzhľad
    'desktop_small': Size(56, 56),   // Pre desktop, kompaktný vzhľad
    'desktop_medium': Size(72, 72),  // Pre desktop, štandardný vzhľad
    'desktop_large': Size(96, 96),   // Pre desktop, výrazný vzhľad
  };
  
  /// Získa odporúčanú veľkosť podľa typu zariadenia a preferencií
  static Size getRecommendedSize({
    required String deviceType, // 'mobile', 'tablet', 'desktop'
    required String preference, // 'small', 'medium', 'large'
  }) {
    final key = '${deviceType}_$preference';
    return recommendedSizes[key] ?? recommendedSizes['mobile_medium']!;
  }
  
  /// Dynamická veľkosť podľa zoom levelu
  static Size getSizeForZoomLevel(double zoomLevel) {
    if (zoomLevel >= 18) {
      return Size(80, 80); // Veľmi blízko - veľký marker
    } else if (zoomLevel >= 15) {
      return Size(64, 64); // Blízko - stredný marker
    } else if (zoomLevel >= 12) {
      return Size(48, 48); // Stredná vzdialenosť - menší marker
    } else {
      return Size(32, 32); // Ďaleko - malý marker
    }
  }
}

/// Widget pre testovanie rôznych veľkostí markerov
class MarkerSizeTestWidget extends StatefulWidget {
  const MarkerSizeTestWidget({super.key});

  @override
  State<MarkerSizeTestWidget> createState() => _MarkerSizeTestWidgetState();
}

class _MarkerSizeTestWidgetState extends State<MarkerSizeTestWidget> {
  Map<String, BitmapDescriptor> _markers = {};
  bool _isLoading = true;
  String _selectedSize = 'medium';

  @override
  void initState() {
    super.initState();
    _loadAllMarkers();
  }

  Future<void> _loadAllMarkers() async {
    setState(() => _isLoading = true);
    
    final markers = await MarkerSizeUtility.loadAllSizes('assets/icons/kavMapIcon.png');
    
    setState(() {
      _markers = markers;
      _isLoading = false;
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
        title: const Text('Test Veľkostí Markerov'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllMarkers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Dropdown pre výber veľkosti
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              value: _selectedSize,
              decoration: const InputDecoration(
                labelText: 'Vyberte veľkosť markeru',
                border: OutlineInputBorder(),
              ),
              items: MarkerSizeUtility.standardSizes.keys.map((size) {
                final dimensions = MarkerSizeUtility.standardSizes[size]!;
                return DropdownMenuItem(
                  value: size,
                  child: Text('$size (${dimensions.width.toInt()}x${dimensions.height.toInt()})'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSize = value!;
                });
              },
            ),
          ),
          
          // Mapa s vybraným markerom
          Expanded(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(48.1486, 17.1077),
                zoom: 15.0,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('test_marker'),
                  position: const LatLng(48.1486, 17.1077),
                  icon: _markers[_selectedSize] ?? BitmapDescriptor.defaultMarker,
                  infoWindow: InfoWindow(
                    title: 'Test Marker',
                    snippet: 'Veľkosť: $_selectedSize (${MarkerSizeUtility.standardSizes[_selectedSize]?.width.toInt()}x${MarkerSizeUtility.standardSizes[_selectedSize]?.height.toInt()})',
                  ),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
} 