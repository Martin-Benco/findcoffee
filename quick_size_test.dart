import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Rýchly test pre rôzne veľkosti markerov
class QuickSizeTest extends StatefulWidget {
  const QuickSizeTest({super.key});

  @override
  State<QuickSizeTest> createState() => _QuickSizeTestState();
}

class _QuickSizeTestState extends State<QuickSizeTest> {
  BitmapDescriptor? _currentMarker;
  double _currentSize = 80.0; // Začneme s 80x80
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMarker(_currentSize);
  }

  Future<void> _loadMarker(double size) async {
    setState(() => _isLoading = true);
    
    try {
      final marker = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(size, size)),
        'assets/icons/kavamark.png',
      );
      
      setState(() {
        _currentMarker = marker;
        _currentSize = size;
        _isLoading = false;
      });
    } catch (e) {
      print('Chyba pri načítaní markeru: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Veľkosti Markeru'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadMarker(_currentSize),
          ),
        ],
      ),
      body: Column(
        children: [
          // Kontrolky pre veľkosť
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                Text(
                  'Aktuálna veľkosť: ${_currentSize.toInt()}x${_currentSize.toInt()}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                // Slider pre plynulú zmenu
                Row(
                  children: [
                    const Text('32'),
                    Expanded(
                      child: Slider(
                        value: _currentSize,
                        min: 32,
                        max: 120,
                        divisions: 22, // (120-32)/4 = 22 divisions
                        label: '${_currentSize.toInt()}',
                        onChanged: (value) {
                          _loadMarker(value);
                        },
                      ),
                    ),
                    const Text('120'),
                  ],
                ),
                
                // Rýchle tlačidlá pre bežné veľkosti
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildSizeButton(32, '32'),
                    _buildSizeButton(48, '48'),
                    _buildSizeButton(64, '64'),
                    _buildSizeButton(80, '80'),
                    _buildSizeButton(96, '96'),
                    _buildSizeButton(120, '120'),
                  ],
                ),
                
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Načítavam...'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Mapa
          Expanded(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(48.1486, 17.1077),
                zoom: 15.0,
              ),
              markers: _currentMarker != null ? {
                Marker(
                  markerId: const MarkerId('test_marker'),
                  position: const LatLng(48.1486, 17.1077),
                  icon: _currentMarker!,
                  infoWindow: InfoWindow(
                    title: 'Test Marker',
                    snippet: 'Veľkosť: ${_currentSize.toInt()}x${_currentSize.toInt()}',
                  ),
                ),
              } : {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeButton(double size, String label) {
    final isSelected = _currentSize == size;
    return ElevatedButton(
      onPressed: () => _loadMarker(size),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label),
    );
  }
}

/// Odporúčania pre veľkosti markerov z Figmy
class FigmaMarkerRecommendations {
  
  /// Odporúčané veľkosti pre ikony z Figmy
  static const Map<String, String> recommendations = {
    '32x32': 'Veľmi malá - vhodná pre kompaktné zobrazenie',
    '48x48': 'Malá - štandardná veľkosť pre mobilné zariadenia',
    '64x64': 'Stredná - dobrá viditeľnosť na všetkých zariadeniach',
    '80x80': 'Veľká - výrazná, vhodná pre dôležité lokácie',
    '96x96': 'Veľmi veľká - maximálna viditeľnosť',
    '120x120': 'Extra veľká - pre špeciálne použitia',
  };
  
  /// Získa odporúčanie pre konkrétnu veľkosť
  static String getRecommendation(double size) {
    final sizeKey = '${size.toInt()}x${size.toInt()}';
    return recommendations[sizeKey] ?? 'Vlastná veľkosť';
  }
  
  /// Odporúčania podľa použitia
  static const Map<String, double> usageRecommendations = {
    'kompaktné_zobrazenie': 32,
    'mobilné_štandard': 48,
    'mobilné_výrazné': 64,
    'tablet_štandard': 80,
    'tablet_výrazné': 96,
    'desktop_štandard': 64,
    'desktop_výrazné': 80,
    'špeciálne_použitia': 120,
  };
} 