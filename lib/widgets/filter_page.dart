import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum SortOption { distance, rating, name }
enum FilterFeatures { wifi, parking, menu }

class FilterPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onApplyFilters;
  final Map<String, dynamic>? initialFilters;
  
  const FilterPage({
    super.key,
    required this.onApplyFilters,
    this.initialFilters,
  });

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  SortOption? _selectedSort;
  double? _selectedMinRating;
  double? _selectedMaxDistance;
  Set<FilterFeatures> _selectedFeatures = {};
  
  // Počiatočné hodnoty pre porovnanie zmien
  final SortOption _initialSort = SortOption.distance;
  final double? _initialMinRating = null;
  final double? _initialMaxDistance = null;
  final Set<FilterFeatures> _initialFeatures = {};
  
  // Premenné na sledovanie, či používateľ niečo zmenil
  bool _hasUserChangedSort = false;
  bool _hasUserChangedRating = false;
  bool _hasUserChangedDistance = false;
  bool _hasUserChangedFeatures = false;

  @override
  void initState() {
    super.initState();
    _setFiltersFromInitial(widget.initialFilters);
  }

  @override
  void didUpdateWidget(covariant FilterPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFilters != oldWidget.initialFilters) {
      _setFiltersFromInitial(widget.initialFilters);
    }
  }

  void _setFiltersFromInitial(Map<String, dynamic>? f) {
    setState(() {
      _selectedSort = f?['sort'];
      _selectedMinRating = f?['minRating'];
      _selectedMaxDistance = f?['maxDistance'];
      _selectedFeatures = (f?['features'] as List?)?.map((e) => e as FilterFeatures).toSet() ?? {};
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Krížik vľavo
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.close,
                    size: 24,
                    color: Color(0xFF603013),
                  ),
                ),
                // Názov v strede
                const Expanded(
                  child: Center(
                    child: Text(
                      'Filtre',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF603013),
                      ),
                    ),
                  ),
                ),
                // Resetovať vpravo - zobraz len ak je niečo aktívne
                if (_selectedSort != null || _selectedMinRating != null || _selectedMaxDistance != null || _selectedFeatures.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedSort = null;
                        _selectedMinRating = null;
                        _selectedMaxDistance = null;
                        _selectedFeatures.clear();
                        _hasUserChangedSort = false;
                        _hasUserChangedRating = false;
                        _hasUserChangedDistance = false;
                        _hasUserChangedFeatures = false;
                      });
                      widget.onApplyFilters({
                        'sort': null,
                        'minRating': null,
                        'maxDistance': null,
                        'features': <FilterFeatures>[]
                      });
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Resetovať',
                      style: TextStyle(
                        color: Color(0xFF603013),
                        fontSize: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sort section
                  _buildSectionTitle('Zoradiť podľa'),
                  const SizedBox(height: 12),
                  _buildSortOptions(),
                  const SizedBox(height: 24),
                  
                  // Rating section
                  _buildSectionTitle('Minimálne hodnotenie'),
                  const SizedBox(height: 12),
                  _buildRatingOptions(),
                  const SizedBox(height: 24),
                  
                  // Distance section
                  _buildSectionTitle('Maximálna vzdialenosť'),
                  const SizedBox(height: 12),
                  _buildDistanceOptions(),
                  const SizedBox(height: 24),
                  
                  // Features section
                  _buildSectionTitle('Služby'),
                  const SizedBox(height: 12),
                  _buildFeaturesOptions(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          
          // Apply button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: ElevatedButton(
                  onPressed: _hasChanges() ? _applyFilters : null,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                      if (states.contains(MaterialState.disabled)) {
                        return const Color(0xFF603013).withOpacity(0.3);
                      }
                      return const Color(0xFF603013);
                    }),
                    foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                      if (states.contains(MaterialState.disabled)) {
                        return Colors.white.withOpacity(0.7);
                      }
                      return Colors.white;
                    }),
                    side: MaterialStateProperty.resolveWith<BorderSide>((states) {
                      if (states.contains(MaterialState.disabled)) {
                        return BorderSide(
                          color: const Color(0xFF603013).withOpacity(0.3),
                          width: 1,
                        );
                      }
                      return const BorderSide(
                        color: Color(0xFF603013),
                        width: 1,
                      );
                    }),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  child: const Text(
                    'Použiť',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF603013),
      ),
    );
  }

  Widget _buildSortOptions() {
    return Column(
      children: SortOption.values.map((option) {
        final isSelected = _selectedSort == option;
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedSort = null;
              } else {
                _selectedSort = option;
              }
            });
          },
          child: ListTile(
            leading: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF603013) : Colors.grey,
                  width: 2,
                ),
                color: isSelected ? const Color(0xFF603013) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.circle, size: 16, color: Colors.white)
                  : null,
            ),
            title: Text(_getSortOptionText(option)),
            contentPadding: EdgeInsets.zero,
          ),
        );
      }).toList(),
    );
  }

  String _getSortOptionText(SortOption option) {
    switch (option) {
      case SortOption.distance:
        return 'Vzdialenosť (najbližšie)';
      case SortOption.rating:
        return 'Hodnotenie (najlepšie)';
      case SortOption.name:
        return 'Názov (A-Z)';
    }
  }

  Widget _buildRatingOptions() {
    return Row(
      children: [
        Expanded(
          child: _buildOptionButton(
            '4.0+',
            _selectedMinRating == 4.0,
            () => setState(() {
              _selectedMinRating = _selectedMinRating == 4.0 ? null : 4.0;
              // Ak sa vráti na predvolené nastavenie, resetujeme sledovanie
              if (_selectedMinRating == null) {
                _hasUserChangedRating = false;
              } else {
                _hasUserChangedRating = true;
              }
            }),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOptionButton(
            '4.4+',
            _selectedMinRating == 4.4,
            () => setState(() {
              _selectedMinRating = _selectedMinRating == 4.4 ? null : 4.4;
              // Ak sa vráti na predvolené nastavenie, resetujeme sledovanie
              if (_selectedMinRating == null) {
                _hasUserChangedRating = false;
              } else {
                _hasUserChangedRating = true;
              }
            }),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOptionButton(
            '4.7+',
            _selectedMinRating == 4.7,
            () => setState(() {
              _selectedMinRating = _selectedMinRating == 4.7 ? null : 4.7;
              // Ak sa vráti na predvolené nastavenie, resetujeme sledovanie
              if (_selectedMinRating == null) {
                _hasUserChangedRating = false;
              } else {
                _hasUserChangedRating = true;
              }
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceOptions() {
    return Row(
      children: [
        Expanded(
          child: _buildOptionButton(
            '1 km',
            _selectedMaxDistance == 1.0,
            () => setState(() {
              _selectedMaxDistance = _selectedMaxDistance == 1.0 ? null : 1.0;
              // Ak sa vráti na predvolené nastavenie, resetujeme sledovanie
              if (_selectedMaxDistance == null) {
                _hasUserChangedDistance = false;
              } else {
                _hasUserChangedDistance = true;
              }
            }),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOptionButton(
            '5 km',
            _selectedMaxDistance == 5.0,
            () => setState(() {
              _selectedMaxDistance = _selectedMaxDistance == 5.0 ? null : 5.0;
              // Ak sa vráti na predvolené nastavenie, resetujeme sledovanie
              if (_selectedMaxDistance == null) {
                _hasUserChangedDistance = false;
              } else {
                _hasUserChangedDistance = true;
              }
            }),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOptionButton(
            '10 km',
            _selectedMaxDistance == 10.0,
            () => setState(() {
              _selectedMaxDistance = _selectedMaxDistance == 10.0 ? null : 10.0;
              // Ak sa vráti na predvolené nastavenie, resetujeme sledovanie
              if (_selectedMaxDistance == null) {
                _hasUserChangedDistance = false;
              } else {
                _hasUserChangedDistance = true;
              }
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF603013).withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF603013) : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFF603013) : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesOptions() {
    return Column(
      children: [
        _buildFeatureOption(FilterFeatures.wifi, 'WiFi', 'assets/icons/wifihnede.svg'),
        const SizedBox(height: 12),
        _buildFeatureOption(FilterFeatures.parking, 'Parkovanie', 'assets/icons/parkinghnede.svg'),
        const SizedBox(height: 12),
        _buildFeatureOption(FilterFeatures.menu, 'Menu', 'assets/icons/menuhnede.svg'),
      ],
    );
  }

  Widget _buildFeatureOption(FilterFeatures feature, String title, String iconPath) {
    final isSelected = _selectedFeatures.contains(feature);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedFeatures.remove(feature);
          } else {
            _selectedFeatures.add(feature);
          }
          // Ak sa vráti na predvolené nastavenie (prázdny set), resetujeme sledovanie
          if (_selectedFeatures.isEmpty) {
            _hasUserChangedFeatures = false;
          } else {
            _hasUserChangedFeatures = true;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF603013).withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF603013) : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              iconPath,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                isSelected ? const Color(0xFF603013) : Colors.grey[600]!,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF603013) : Colors.black87,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF603013),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  bool _hasChanges() {
    final f = widget.initialFilters;
    final initialSort = f?['sort'];
    final initialMinRating = f?['minRating'];
    final initialMaxDistance = f?['maxDistance'];
    final initialFeatures = (f?['features'] as List?)?.map((e) => e as FilterFeatures).toSet() ?? {};
    return _selectedSort != initialSort ||
           _selectedMinRating != initialMinRating ||
           _selectedMaxDistance != initialMaxDistance ||
           _selectedFeatures.length != initialFeatures.length ||
           !_selectedFeatures.containsAll(initialFeatures);
  }

  void _resetFilters() {
    setState(() {
      _selectedSort = null;
      _selectedMinRating = null;
      _selectedMaxDistance = null;
      _selectedFeatures.clear();
      _hasUserChangedSort = false;
      _hasUserChangedRating = false;
      _hasUserChangedDistance = false;
      _hasUserChangedFeatures = false;
    });
  }

  void _applyFilters() {
    final filters = {
      'sort': _selectedSort,
      'minRating': _selectedMinRating,
      'maxDistance': _selectedMaxDistance,
      'features': _selectedFeatures.toList(),
    };
    
    widget.onApplyFilters(filters);
    Navigator.of(context).pop();
  }
} 