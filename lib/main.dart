import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'core/theme/app_text_styles.dart';
import 'widgets/section_title.dart';
import 'widgets/drink_carousel.dart';
import 'widgets/cafe_carousel.dart';
import 'widgets/food_carousel.dart';
import 'core/models.dart';
import 'core/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const CoffitApp());
}

class CoffitApp extends StatelessWidget {
  const CoffitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coffit',
      theme: AppTheme.lightTheme,
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    FavoritesPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontSize: 12.36),
        unselectedLabelStyle: const TextStyle(fontSize: 12.36),
        selectedItemColor: AppColors.black,
        unselectedItemColor: AppColors.black,
        items: [
          BottomNavigationBarItem(
            icon: SizedBox(
              width: 24,
              height: 24,
              child: SvgPicture.asset(
                _selectedIndex == 0
                  ? 'assets/icons/housePlne.svg'
                  : 'assets/icons/houseEmpty.svg',
              ),
            ),
            label: 'Domov',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(
              width: 24,
              height: 24,
              child: SvgPicture.asset(
                _selectedIndex == 1
                  ? 'assets/icons/cierneHeartPlne.svg'
                  : 'assets/icons/cierneHeartEmpty.svg',
              ),
            ),
            label: 'Obľúbené',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(
              width: 24,
              height: 24,
              child: SvgPicture.asset(
                _selectedIndex == 2
                  ? 'assets/icons/userPlne.svg'
                  : 'assets/icons/userEmpty.svg',
              ),
            ),
            label: 'Účet',
          ),
        ],
      ),
    );
  }
}

// ------------------- Home Page -------------------
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

enum HomeMode { search, searchMap, map }

class _HomePageState extends State<HomePage> {
  HomeMode _mode = HomeMode.map;
  final FirebaseService _firebaseService = FirebaseService();
  Position? _currentPosition;
  final TextEditingController _searchController = TextEditingController();
  
  // Mock dáta pre nápoje a jedlá (zatiaľ)
  final List<Drink> _drinks = const [
    Drink(name: 'Matcha', imageUrl: 'assets/images/matcha.jpg'),
    Drink(name: 'Káva', imageUrl: 'assets/images/kava.jpg'),
    Drink(name: 'Drinky', imageUrl: 'assets/images/drinky.jpg'),
    Drink(name: 'Limonáda', imageUrl: 'assets/images/limonady.jpg'),
    Drink(name: 'Kombucha', imageUrl: 'assets/images/kombucha.jpg'),
  ];
  
  List<Cafe> _cafes = [];
  List<Cafe> _filteredCafes = [];
  List<Cafe> _searchResults = [];
  bool _isLoadingCafes = true;
  bool _isFiltered = false;
  bool _isSearching = false;
  String? _selectedDrink;
  String? _selectedFood;
  
  final List<Food> _foods = const [
    Food(name: 'Sandwich', imageUrl: 'assets/images/sandwich.jpg'),
    Food(name: 'Koláče', imageUrl: 'assets/images/kolace.jpg'),
    Food(name: 'Cinnamon rolls', imageUrl: 'assets/images/cinnamonRolls.jpg'),
    Food(name: 'Croissant', imageUrl: 'assets/images/croissant.jpg'),
    Food(name: 'Pistachio', imageUrl: 'assets/images/pistachio.jpg'),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _getCurrentLocation();
    await _loadAndProcessCafes();
  }

  /// Získa aktuálnu polohu používateľa
  Future<void> _getCurrentLocation() async {
    try {
      print("Zisťujem polohu používateľa...");
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        print("Povolenie na prístup k polohe zamietnuté. Žiadam znova.");
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print("Povolenie na prístup k polohe trvalo zamietnuté.");
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        print("Povolenie na prístup k polohe trvalo zamietnuté.");
        return;
      }
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print("Poloha používateľa úspešne získaná: $_currentPosition");
    } catch (e) {
      print("Chyba pri získavaní polohy: $e");
    }
  }

  /// Načíta kaviarne z Firebase
  Future<void> _loadAndProcessCafes() async {
    try {
      if (!mounted) return;
      setState(() => _isLoadingCafes = true);
      
      final cafes = await _firebaseService.getCafes();
      print("Počet načítaných kaviarní: ${cafes.length}");

      if (_currentPosition != null) {
        print("Spracovávam kaviarne a počítam vzdialenosti...");
        for (var cafe in cafes) {
          final distanceInMeters = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            cafe.latitude,
            cafe.longitude,
          );
          cafe.distanceKm = distanceInMeters / 1000;
          print("- Kaviareň '${cafe.name}': vzdialenosť ${cafe.distanceKm.toStringAsFixed(2)} km");
        }
        cafes.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
        print("Kaviarne zotriedené podľa vzdialenosti.");
      } else {
        print("Poloha používateľa nie je dostupná. Vzdialenosti nebudú vypočítané.");
      }

      if (mounted) {
        setState(() {
          _cafes = cafes;
          _isLoadingCafes = false;
        });
      }
    } catch (e) {
      print('Chyba pri načítaní a spracovaní kaviarní: $e');
      if (mounted) {
        setState(() => _isLoadingCafes = false);
      }
    }
  }

  /// Spracuje kliknutie na nápoj a načíta filtrované kaviarne
  Future<void> _onDrinkTap(String drinkName) async {
    try {
      setState(() {
        _isLoadingCafes = true;
        _isFiltered = true;
        _selectedDrink = drinkName;
        _selectedFood = null; // Zrušíme filter jedla
      });

      print("Kliknutie na nápoj: $drinkName");
      
      final filteredCafes = await _firebaseService.getCafesByMenuItem(drinkName);
      print("Načítaných ${filteredCafes.length} kaviarní s $drinkName");

      if (_currentPosition != null) {
        print("Spracovávam filtrované kaviarne a počítam vzdialenosti...");
        for (var cafe in filteredCafes) {
          final distanceInMeters = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            cafe.latitude,
            cafe.longitude,
          );
          cafe.distanceKm = distanceInMeters / 1000;
          print("- Kaviareň '${cafe.name}': vzdialenosť ${cafe.distanceKm.toStringAsFixed(2)} km");
        }
        filteredCafes.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      }

      if (mounted) {
        setState(() {
          _filteredCafes = filteredCafes;
          _isLoadingCafes = false;
        });
      }
    } catch (e) {
      print('Chyba pri načítaní filtrovaných kaviarní: $e');
      if (mounted) {
        setState(() => _isLoadingCafes = false);
      }
    }
  }

  /// Spracuje kliknutie na jedlo a načíta filtrované kaviarne
  Future<void> _onFoodTap(String foodName) async {
    try {
      setState(() {
        _isLoadingCafes = true;
        _isFiltered = true;
        _selectedFood = foodName;
        _selectedDrink = null; // Zrušíme filter nápoja
      });

      print("Kliknutie na jedlo: $foodName");
      
      final filteredCafes = await _firebaseService.getCafesByMenuItem(foodName);
      print("Načítaných ${filteredCafes.length} kaviarní s $foodName");

      if (_currentPosition != null) {
        print("Spracovávam filtrované kaviarne a počítam vzdialenosti...");
        for (var cafe in filteredCafes) {
          final distanceInMeters = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            cafe.latitude,
            cafe.longitude,
          );
          cafe.distanceKm = distanceInMeters / 1000;
          print("- Kaviareň '${cafe.name}': vzdialenosť ${cafe.distanceKm.toStringAsFixed(2)} km");
        }
        filteredCafes.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      }

      if (mounted) {
        setState(() {
          _filteredCafes = filteredCafes;
          _isLoadingCafes = false;
        });
      }
    } catch (e) {
      print('Chyba pri načítaní filtrovaných kaviarní: $e');
      if (mounted) {
        setState(() => _isLoadingCafes = false);
      }
    }
  }

  /// Zruší filtrovanie a zobrazí všetky kaviarne
  void _clearFilter() {
    setState(() {
      _isFiltered = false;
      _selectedDrink = null;
      _selectedFood = null;
      _filteredCafes.clear();
    });
  }

  /// Vyhľadá kaviarne podľa názvu
  void _searchCafes(String query) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isFiltered = false; // Zrušíme filter pri vyhľadávaní
    });

    final lowercaseQuery = query.toLowerCase();
    final results = _cafes.where((cafe) {
      return cafe.name.toLowerCase().contains(lowercaseQuery);
    }).toList();

    setState(() {
      _searchResults = results;
    });
  }

  /// Zruší vyhľadávanie
  void _clearSearch() {
    setState(() {
      _isSearching = false;
      _searchResults.clear();
      _searchController.clear();
    });
  }

  /// Skontroluje, či je query nápoj alebo jedlo a aplikuje filter
  void _handleSearchQuery(String query) {
    final lowercaseQuery = query.toLowerCase();
    
    // Skontrolujeme, či sa query zhoduje s nejakým nápojom
    final matchingDrink = _drinks.firstWhere(
      (drink) => drink.name.toLowerCase() == lowercaseQuery,
      orElse: () => const Drink(name: '', imageUrl: ''),
    );
    
    // Skontrolujeme, či sa query zhoduje s nejakým jedlom
    final matchingFood = _foods.firstWhere(
      (food) => food.name.toLowerCase() == lowercaseQuery,
      orElse: () => const Food(name: '', imageUrl: ''),
    );

    if (matchingDrink.name.isNotEmpty) {
      _onDrinkTap(matchingDrink.name);
    } else if (matchingFood.name.isNotEmpty) {
      _onFoodTap(matchingFood.name);
    } else {
      // Ak sa nejedná o presný match s nápojom/jedlom, vyhľadáme kaviarne
      _searchCafes(query);
    }
  }

  void _onSheetChanged(double extent) {
    // Nastav režim podľa výšky sheetu
    if (extent < 0.35) {
      if (_mode != HomeMode.map) setState(() => _mode = HomeMode.map);
    } else if (extent < 0.85) {
      if (_mode != HomeMode.searchMap) setState(() => _mode = HomeMode.searchMap);
    } else {
      if (_mode != HomeMode.search) setState(() => _mode = HomeMode.search);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Mapa je vždy na pozadí
        _MapView(currentPosition: _currentPosition),
        DraggableScrollableSheet(
          initialChildSize: 0.12, // cca výška search baru
          minChildSize: 0.12,
          maxChildSize: 1.0,
          snap: true,
          snapSizes: const [0.12, 0.75, 1.0],
          builder: (context, scrollController) {
            return NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                _onSheetChanged(notification.extent);
                return true;
              },
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.grey,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 16),
                            SvgPicture.asset(
                              'assets/icons/searchLupa.svg',
                              width: 24,
                              height: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: const InputDecoration(
                                  hintText: 'Vyhľadávanie kaviarní, nápojov...',
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                style: AppTextStyles.regular12,
                                onChanged: (value) {
                                  if (value.isEmpty) {
                                    _clearSearch();
                                  } else {
                                    _handleSearchQuery(value);
                                  }
                                },
                                onSubmitted: (value) {
                                  _handleSearchQuery(value);
                                },
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              GestureDetector(
                                onTap: _clearSearch,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 16.0),
                                  child: SvgPicture.asset(
                                    'assets/icons/bieleX.svg',
                                    width: 20,
                                    height: 20,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle('Populárne nápoje', isLarge: true),
                    DrinkCarousel(
                      drinks: _drinks, 
                      height: 140, 
                      itemSize: 96,
                      onDrinkTap: _onDrinkTap,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: SectionTitle(
                            _isSearching 
                              ? 'Výsledky vyhľadávania'
                              : _isFiltered 
                                ? _selectedDrink != null 
                                  ? 'Kaviarne s $_selectedDrink' 
                                  : 'Kaviarne s $_selectedFood'
                                : 'Kaviarne v okolí', 
                            isLarge: true
                          ),
                        ),
                        if (_isFiltered || _isSearching)
                          GestureDetector(
                            onTap: _isSearching ? _clearSearch : _clearFilter,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.grey,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/bieleX.svg',
                                    width: 16,
                                    height: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Zrušiť',
                                    style: AppTextStyles.regular12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (_isLoadingCafes)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_isSearching && _searchResults.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            'Žiadne kaviarne neboli nájdené',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else if (_isFiltered && _filteredCafes.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            'Žiadne kaviarne s týmto nápojom neboli nájdené',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else if (!_isFiltered && !_isSearching && _cafes.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            'Žiadne kaviarne neboli nájdené',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      CafeCarousel(
                        cafes: _isSearching 
                          ? _searchResults 
                          : _isFiltered 
                            ? _filteredCafes 
                            : _cafes, 
                        itemWidth: 200, 
                        itemHeight: 140
                      ),
                    if (_mode == HomeMode.search) ...[
                      const SizedBox(height: 24),
                      const SectionTitle('Niečo pod zub', isLarge: true),
                      FoodCarousel(
                        foods: _foods, 
                        height: 140, 
                        itemSize: 96,
                        onFoodTap: _onFoodTap,
                      ),
                      const SizedBox(height: 32),
                    ] else ...[
                      const SizedBox(height: 32),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MapView extends StatefulWidget {
  final Position? currentPosition;
  const _MapView({this.currentPosition});

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  GoogleMapController? _mapController;

  // Počiatočná pozícia (Bratislava) - použije sa, kým sa nezíska aktuálna poloha
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(48.1486, 17.1077),
    zoom: 15.0,
  );

  @override
  void didUpdateWidget(covariant _MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPosition != null && widget.currentPosition != oldWidget.currentPosition) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(widget.currentPosition!.latitude, widget.currentPosition!.longitude),
            zoom: 15.0,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        
        // Ak už máme aktuálnu polohu, presunieme kameru
        if (widget.currentPosition != null) {
          controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(widget.currentPosition!.latitude, widget.currentPosition!.longitude),
                zoom: 15.0,
              ),
            ),
          );
        }
      },
      initialCameraPosition: widget.currentPosition != null
          ? CameraPosition(
              target: LatLng(widget.currentPosition!.latitude, widget.currentPosition!.longitude),
              zoom: 15.0,
            )
          : _initialPosition,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

// ------------------- Favorites Page -------------------
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(child: Text('Obľúbené', style: TextStyle(fontSize: 18))),
    );
  }
}

// ------------------- Profile Page -------------------
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(child: Text('Účet', style: TextStyle(fontSize: 18))),
    );
  }
}
