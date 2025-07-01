import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Debug widget pre testovanie markerov
class DebugMarkerTest extends StatefulWidget {
  const DebugMarkerTest({super.key});

  @override
  State<DebugMarkerTest> createState() => _DebugMarkerTestState();
}

class _DebugMarkerTestState extends State<DebugMarkerTest> {
  BitmapDescriptor? _testMarker;
  double _currentSize = 120.0;
  bool _isLoading = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _loadTestMarker();
  }

  Future<void> _loadTestMarker() async {
    setState(() {
      _isLoading = true;
      _status = 'Načítavam marker...';
    });

    try {
      print('🧪 DEBUG: Načítavam test marker s veľkosťou ${_currentSize.toInt()}x${_currentSize.toInt()}');
      
      final marker = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(_currentSize, _currentSize)),
        'assets/icons/kavMapIcon.png',
      );
      
      setState(() {
        _testMarker = marker;
        _isLoading = false;
        _status = '✅ Marker načítaný: ${_currentSize.toInt()}x${_currentSize.toInt()}';
      });
      
      print('🧪 DEBUG: Marker úspešne načítaný');
    } catch (e) {
      print('🧪 DEBUG: Chyba pri načítaní markeru: $e');
      setState(() {
        _isLoading = false;
        _status = '❌ Chyba: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Marker Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTestMarker,
          ),
        ],
      ),
      body: Column(
        children: [
          // Debug panel
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              children: [
                Text(
                  'Status: $_status',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                // Veľkosť slider
                Row(
                  children: [
                    const Text('32'),
                    Expanded(
                      child: Slider(
                        value: _currentSize,
                        min: 32,
                        max: 200,
                        divisions: 42,
                        label: '${_currentSize.toInt()}',
                        onChanged: (value) {
                          setState(() {
                            _currentSize = value;
                            _status = 'Zmenená veľkosť na ${value.toInt()}x${value.toInt()}';
                          });
                        },
                        onChangeEnd: (value) {
                          _loadTestMarker();
                        },
                      ),
                    ),
                    const Text('200'),
                  ],
                ),
                
                // Rýchle tlačidlá
                Wrap(
                  spacing: 8,
                  children: [
                    _buildSizeButton(48, '48'),
                    _buildSizeButton(80, '80'),
                    _buildSizeButton(120, '120'),
                    _buildSizeButton(160, '160'),
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
              markers: _testMarker != null ? {
                Marker(
                  markerId: const MarkerId('debug_marker'),
                  position: const LatLng(48.1486, 17.1077),
                  icon: _testMarker!,
                  infoWindow: InfoWindow(
                    title: 'Debug Marker',
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
      onPressed: () {
        setState(() {
          _currentSize = size;
        });
        _loadTestMarker();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label),
    );
  }
} 