import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import 'widgets/filter_page.dart';
import 'core/models.dart';
import 'core/firebase_service.dart';
import 'core/auth_service.dart';
import 'core/shared_preferences_service.dart';
import 'widgets/login_sheet.dart';
import 'widgets/register_sheet.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'widgets/cafe_detail_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'widgets/cafe_info_bottom_sheet.dart';
import 'widgets/privacy_screen.dart';
import 'widgets/info_screen.dart';
import 'package:geocoding/geocoding.dart';
import 'core/utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "TVOJ_API_KEY",
        authDomain: "TVOJ_AUTH_DOMAIN",
        projectId: "TVOJ_PROJECT_ID",
        storageBucket: "TVOJ_STORAGE_BUCKET",
        messagingSenderId: "TVOJ_MESSAGING_SENDER_ID",
        appId: "TVOJ_APP_ID",
        measurementId: "TVOJ_MEASUREMENT_ID",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  runApp(const CoffitApp());
}

class CoffitApp extends StatelessWidget {
  const CoffitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coffit',
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          // Používateľ je prihlásený
          return const MainNavigation();
        } else {
          // Používateľ nie je prihlásený
          return const AuthScreen();
        }
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _showLogin = false;
  bool _showRegister = false;

  void _openLogin() => setState(() { _showLogin = true; _showRegister = false; });
  void _openRegister() => setState(() { _showRegister = true; _showLogin = false; });
  void _closeSheet() => setState(() { _showLogin = false; _showRegister = false; });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Pozadie cez celý screen
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_coffee.png',
              fit: BoxFit.cover,
            ),
          ),
          // Obsah
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 80),
                    const Text(
                      'Vitajte',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        color: Color(0xFF603013),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Zadajte svoje osobné údaje pre používanie tejto aplikácie.',
                        style: TextStyle(
                          color: Color(0xFF603013),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: 260,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF603013),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _openRegister,
                        child: const Text('Registrovať sa', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 260,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF603013),
                          side: const BorderSide(color: Color(0xFF603013), width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _openLogin,
                        child: const Text('Prihlásiť sa', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Sheet pre login/register
          if (_showLogin || _showRegister)
            GestureDetector(
              onTap: _closeSheet,
              child: Container(
                color: Colors.black.withOpacity(0.3),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          if (_showLogin)
            _BottomSheetContainer(
              child: LoginSheet(
                onRegisterTap: _openRegister,
                onLoginSuccess: _closeSheet,
              ),
            ),
          if (_showRegister)
            _BottomSheetContainer(
              child: RegisterSheet(
                onLoginTap: _openLogin,
                onRegisterSuccess: _closeSheet,
              ),
            ),
        ],
      ),
    );
  }
}

class _BottomSheetContainer extends StatelessWidget {
  final Widget child;
  const _BottomSheetContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      left: 0,
      right: 0,
      bottom: 0,
      top: MediaQuery.of(context).size.height * 0.18,
      child: Material(
        elevation: 16,
        color: Colors.transparent,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: child,
        ),
      ),
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
  final FirebaseService _firebaseService = FirebaseService();
  Position? _currentPosition;
  List<Cafe> _cafes = [];
  bool _isLoadingCafes = true;
  
  // Cache pre pages
  final List<Widget> _pages = [];

  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Vytvoríme pages len raz
    if (_pages.isEmpty) {
      _pages.addAll([
        HomePage(
          currentPosition: _currentPosition,
          cafes: _cafes,
          firebaseService: _firebaseService,
        ),
        FavoritesPage(),
        ProfilePage(),
      ]);
    } else {
      // Aktualizujeme HomePage s novými dátami
      _pages[0] = HomePage(
        currentPosition: _currentPosition,
        cafes: _cafes,
        firebaseService: _firebaseService,
      );
    }

    return Scaffold(
      body: _isLoadingCafes 
        ? const Center(child: CircularProgressIndicator())
        : _pages.isNotEmpty ? _pages[_selectedIndex] : const SizedBox(),
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
  final Position? currentPosition;
  final List<Cafe> cafes;
  final FirebaseService firebaseService;
  
  const HomePage({
    super.key, 
    required this.currentPosition, 
    required this.cafes, 
    required this.firebaseService
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

enum HomeMode { search, searchMap, map }

class _HomePageState extends State<HomePage> {
  HomeMode _mode = HomeMode.map;
  Position? _currentPosition;
  final TextEditingController _searchController = TextEditingController();
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;
  double _sheetExtent = 0.75; // Pridám premennú na sledovanie pozície sheetu
  
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
  bool _isLoadingCafes = false;
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

  List<Map<String, dynamic>> _activeFilters = [];
  SortOption? _selectedSort;
  double? _selectedMinRating;
  double? _selectedMaxDistance;
  Set<FilterFeatures> _selectedFeatures = {};
  Cafe? _selectedCafe;
  bool _showCafeSheet = false;

  String? _currentAddress;
  String? _selectedCity;
  bool _isLocationLoading = false;
  final List<String> _citySuggestions = [
    'Bratislava', 'Košice', 'Prešov', 'Žilina', 'Nitra',
    'Banská Bystrica', 'Trnava', 'Trenčín', 'Martin', 'Poprad',
    'Senica', 'Bardejov', 'Liptovský Mikuláš', 'Dunajská Streda',
  ];

  @override
  void initState() {
    super.initState();
    _cafes = widget.cafes;
    _currentPosition = widget.currentPosition;
    _fetchCurrentLocationAndAddress();
    
    _searchFocusNode.addListener(_onSearchFocusChange);
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cafes != oldWidget.cafes) {
      setState(() {
        _cafes = widget.cafes;
      });
    }
    if (widget.currentPosition != oldWidget.currentPosition) {
      setState(() {
        _currentPosition = widget.currentPosition;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  /// Spracuje kliknutie na nápoj a načíta filtrované kaviarne
  Future<void> _onDrinkTap(String drinkName) async {
    try {
      _animateSheetToSearch();
      _searchController.text = drinkName;
      setState(() {
        _isLoadingCafes = true;
        _isFiltered = true;
        _selectedDrink = drinkName;
        _selectedFood = null; // Zrušíme filter jedla
      });

      print("=== FILTROVANIE NÁPOJA ===");
      print("Kliknutie na nápoj: $drinkName");
      
      final filteredCafes = await widget.firebaseService.getCafesByMenuItem(drinkName);
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
        print("Kaviarne zotriedené podľa vzdialenosti");
      }

      if (mounted) {
        setState(() {
          _filteredCafes = filteredCafes;
          _isLoadingCafes = false;
        });
        print("=== FILTROVANIE DOKONČENÉ ===");
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
      _animateSheetToSearch();
      _searchController.text = foodName;
      setState(() {
        _isLoadingCafes = true;
        _isFiltered = true;
        _selectedFood = foodName;
        _selectedDrink = null; // Zrušíme filter nápoja
      });

      print("=== FILTROVANIE JEDLA ===");
      print("Kliknutie na jedlo: $foodName");
      
      final filteredCafes = await widget.firebaseService.getCafesByMenuItem(foodName);
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
        print("Kaviarne zotriedené podľa vzdialenosti");
      }

      if (mounted) {
        setState(() {
          _filteredCafes = filteredCafes;
          _isLoadingCafes = false;
        });
        print("=== FILTROVANIE DOKONČENÉ ===");
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

  /// Zruší vyhľadávanie a filtrovanie
  void _resetSearchAndFilter() {
    setState(() {
      _searchController.clear();
      _isSearching = false;
      _isFiltered = false;
      _searchResults.clear();
      _filteredCafes.clear();
      _selectedDrink = null;
      _selectedFood = null;
      _sheetExtent = 0.75; // Resetujem pozíciu na default
      FocusScope.of(context).unfocus();
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

  void _animateSheetToSearch() {
    // Skontrolujeme, či je controller pripojený k sheetu
    if (!_sheetController.isAttached) return;

    _sheetController.animateTo(
      1.0, // maxChildSize
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onSheetChanged(double extent) {
    final newMode = extent < 0.35
        ? HomeMode.map
        : extent < 0.85
            ? HomeMode.searchMap
            : HomeMode.search;

    setState(() {
      _sheetExtent = extent; // Aktualizujem pozíciu sheetu
      
      if (newMode != _mode) {
        if (_mode == HomeMode.search && newMode != HomeMode.search) {
          FocusScope.of(context).unfocus();
        }
        _mode = newMode;
      }
    });
  }

  void _applyFiltersAndOpenSearch(Map<String, dynamic> filters) {
    setState(() {
      _selectedSort = filters['sort'];
      _selectedMinRating = filters['minRating'];
      _selectedMaxDistance = filters['maxDistance'];
      _selectedFeatures = (filters['features'] as List?)?.map((e) => e as FilterFeatures).toSet() ?? {};
    });
    _applyFiltersToCafes(filters);
    _updateActiveFilters(filters);
    final isDefault = (filters['minRating'] == null || filters['minRating'] == 0.0)
      && (filters['maxDistance'] == null)
      && (filters['features'] == null || (filters['features'] as List).isEmpty)
      && (filters['sort'] == null);
    if (isDefault) {
      setState(() {
        _mode = HomeMode.map;
        _isFiltered = false;
      });
    } else {
      _animateSheetToSearch();
      setState(() {
        _mode = HomeMode.search;
        _isFiltered = true;
        _sheetExtent = 1.0; // Aktualizujem pozíciu pre search mode
      });
    }
  }

  void _updateActiveFilters(Map<String, dynamic> filters) {
    final List<Map<String, dynamic>> chips = [];
    if (filters['sort'] != null) {
      String label = '';
      if (filters['sort'] == SortOption.name) label = 'A-Z';
      if (filters['sort'] == SortOption.rating) label = 'Hodnotenie';
      if (filters['sort'] == SortOption.distance) label = 'Vzdialenosť';
      chips.add({'type': 'sort', 'label': label, 'sort': filters['sort']});
    }
    if (filters['minRating'] != null) {
      chips.add({'type': 'minRating', 'label': 'od ${filters['minRating']}★'});
    }
    if (filters['maxDistance'] != null) {
      chips.add({'type': 'maxDistance', 'label': 'do ${filters['maxDistance']} km'});
    }
    if (filters['features'] != null && filters['features'].isNotEmpty) {
      for (var f in filters['features']) {
        String label = f.toString().split('.').last;
        if (label == 'wifi') label = 'WiFi';
        if (label == 'parking') label = 'Parkovanie';
        if (label == 'menu') label = 'Menu';
        chips.add({'type': 'feature', 'label': label, 'feature': f});
      }
    }
    setState(() {
      _activeFilters = chips;
    });
  }

  void _removeFilterChip(Map<String, dynamic> chip) {
    // Odstránim chip zo zoznamu a aktualizujem stav filtrov
    setState(() {
      _activeFilters.remove(chip);
      // Aktualizujem stavové premenné podľa zostávajúcich chipov
      _selectedMinRating = _activeFilters.firstWhere((f) => f['type'] == 'minRating', orElse: () => {'label': null})['label'] != null ? double.tryParse(_activeFilters.firstWhere((f) => f['type'] == 'minRating', orElse: () => {'label': null})['label'].toString().replaceAll(RegExp(r'[^0-9\.]'), '')) : null;
      _selectedMaxDistance = _activeFilters.firstWhere((f) => f['type'] == 'maxDistance', orElse: () => {'label': null})['label'] != null ? double.tryParse(_activeFilters.firstWhere((f) => f['type'] == 'maxDistance', orElse: () => {'label': null})['label'].toString().replaceAll(RegExp(r'[^0-9\.]'), '')) : null;
      _selectedFeatures = _activeFilters.where((f) => f['type'] == 'feature').map((f) => f['feature'] as FilterFeatures).toSet();
      // Ak nie sú žiadne filtre, nastavím _isFiltered na false
      _isFiltered = _activeFilters.isNotEmpty;
    });
    // Aplikujem nový stav filtrov
    _applyFiltersAndOpenSearch(_getCurrentFilters());
  }

  void _applyFiltersToCafes(Map<String, dynamic> filters) {
    // Ak nie je žiadny filter aktívny, zobraz všetky kaviarne a default karusely
    if ((filters['minRating'] == null || filters['minRating'] == 0.0) &&
        (filters['maxDistance'] == null) &&
        (filters['features'] == null || (filters['features'] as List).isEmpty)) {
      setState(() {
        _filteredCafes = _cafes;
        _isFiltered = false;
        // Ak nie je nič v search bare, prepni na default mód
        if (_searchController.text.isEmpty) {
          _mode = HomeMode.map;
        }
      });
      return;
    }

    // ... inak aplikuj filtrovanie podľa zadaných filtrov ...
    setState(() {
      _filteredCafes = [];
      _isFiltered = true;
    });
  }

  Map<String, dynamic> _getCurrentFilters() {
    return {
      'sort': _selectedSort,
      'minRating': _selectedMinRating,
      'maxDistance': _selectedMaxDistance,
      'features': _selectedFeatures.toList(),
    };
  }

  void _onSearchFocusChange() {
    final wasFocused = _isSearchFocused;
    _isSearchFocused = _searchFocusNode.hasFocus;
    if (_isSearchFocused && !wasFocused) {
      _mode = HomeMode.search;
      _animateSheetToSearch();
      setState(() {
        _sheetExtent = 1.0; // Aktualizujem pozíciu pre search mode
      });
    } else if (!_isSearchFocused && wasFocused) {
      _mode = HomeMode.map;
      setState(() {
        _sheetExtent = 0.75; // Resetujem pozíciu na default
      });
    }
  }

  void _onCafeSelected(Cafe cafe) {
    setState(() {
      _selectedCafe = cafe;
      _showCafeSheet = true;
    });
  }

  void _closeCafeSheet() {
    if (_showCafeSheet) {
      setState(() {
        _showCafeSheet = false;
        _selectedCafe = null;
      });
    }
  }

  Future<void> _fetchCurrentLocationAndAddress() async {
    setState(() { _isLocationLoading = true; });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!serviceEnabled ||
          permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _currentAddress = null;
          _isLocationLoading = false;
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude, localeIdentifier: 'sk');
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          _currentAddress = '${p.locality ?? ''}${p.locality != null && p.street != null ? ', ' : ''}${p.street ?? ''}${p.subThoroughfare != null ? ' ${p.subThoroughfare}' : ''}';
          _selectedCity = p.locality;
          _isLocationLoading = false;
        });
      } else {
        setState(() {
          _currentAddress = null;
          _isLocationLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress = null;
        _isLocationLoading = false;
      });
    }
  }

  void _showLocationPicker() async {
    String? result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LocationPickerSheet(
        citySuggestions: _citySuggestions,
        onCitySelected: (city) => Navigator.of(context).pop(city),
      ),
    );
    if (result != null && result.isNotEmpty) {
      _moveToCity(result);
    }
  }

  Future<void> _moveToCity(String city) async {
    try {
      List<Location> locations = await locationFromAddress(city + ', Slovakia');
      if (locations.isNotEmpty) {
        final loc = locations.first;
        setState(() {
          _selectedCity = city;
          _currentAddress = city;
          _currentPosition = Position(
            latitude: loc.latitude,
            longitude: loc.longitude,
            timestamp: DateTime.now(),
            accuracy: 1.0,
            altitude: 0.0,
            heading: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
            altitudeAccuracy: 1.0,
            headingAccuracy: 1.0,
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nepodarilo sa nájsť mesto: $city')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _MapView(
          currentPosition: _currentPosition,
          cafes: _cafes,
          onCafeSelected: _onCafeSelected,
          onMapTap: _showCafeSheet ? _closeCafeSheet : null,
          sheetExtent: _sheetExtent, // cca výška search baru
        ),
        if (!_showCafeSheet) ...[
          // Menu button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: GestureDetector(
              onTap: _showLocationPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_outlined, color: Colors.black, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      _isLocationLoading
                        ? 'Načítavam...'
                        : (_currentAddress ?? _selectedCity ?? 'Zvoľte mesto'),
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w400, fontSize: 12.36), // Tenký text ako v navigácii
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, color: Colors.black, size: 16),
                  ],
                ),
              ),
            ),
          ),
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: _sheetExtent, // cca výška search baru
            minChildSize: 0.15,
            maxChildSize: 1.0,
            snap: true,
            snapSizes: const [0.15, 0.75, 1.0],
            builder: (context, scrollController) {
              return NotificationListener<DraggableScrollableNotification>(
                onNotification: (notification) {
                  _onSheetChanged(notification.extent);
                  return true;
                },
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(0)), // Odstránený horný radius
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
                      AnimatedOpacity(
                        opacity: _mode == HomeMode.search ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.ease,
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 8, top: 4), // Zmenšené medzery
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8), // Zmenšená medzera
                      const SizedBox(height: 8), // Zmenšená medzera
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Flexible(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.ease,
                                constraints: BoxConstraints(
                                  minWidth: 0,
                                  maxWidth: _isSearchFocused ? MediaQuery.of(context).size.width - 32 - 70 : MediaQuery.of(context).size.width - 32,
                                ),
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _isSearchFocused ? AppColors.background : AppColors.grey,
                                  borderRadius: BorderRadius.circular(12),
                                  border: _isSearchFocused
                                      ? Border.all(color: AppColors.black, width: 1.0)
                                      : null,
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
                                        focusNode: _searchFocusNode,
                                        textAlignVertical: TextAlignVertical.center,
                                        decoration: const InputDecoration(
                                          isCollapsed: true,
                                          hintText: 'Vyhľadávanie kaviarní',
                                          border: InputBorder.none,
                                          hintStyle: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                        style: AppTextStyles.regular12,
                                        onChanged: (value) {
                                          if (value.isEmpty) {
                                            _resetSearchAndFilter();
                                          } else {
                                            _handleSearchQuery(value);
                                          }
                                          setState(() {});
                                        },
                                        onSubmitted: (value) {
                                          _handleSearchQuery(value);
                                          _searchFocusNode.unfocus();
                                        },
                                        onEditingComplete: () {
                                          _searchFocusNode.unfocus();
                                        },
                                      ),
                                    ),
                                    if (_isSearchFocused)
                                      _searchController.text.isNotEmpty
                                        ? GestureDetector(
                                            onTap: () {
                                              _resetSearchAndFilter();
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.only(right: 0.0),
                                              child: SvgPicture.asset(
                                                'assets/icons/cierneX.svg',
                                                width: 20,
                                                height: 20,
                                              ),
                                            ),
                                          )
                                        : const SizedBox(width: 20)
                                    else
                                      GestureDetector(
                                        onTap: () async {
                                          await showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (context) => FilterPage(
                                              onApplyFilters: (filters) {
                                                _applyFiltersAndOpenSearch(filters);
                                              },
                                              initialFilters: _getCurrentFilters(),
                                            ),
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.only(right: 0.0),
                                          child: SvgPicture.asset(
                                            'assets/icons/filterIcon.svg',
                                            width: 24,
                                            height: 24,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 16),
                                  ],
                                ),
                              ),
                            ),
                            if (_isSearchFocused)
                              AnimatedOpacity(
                                opacity: _isSearchFocused ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: SizedBox(
                                  width: 70,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        _searchFocusNode.unfocus();
                                      },
                                      child: const Text('Zrušiť', style: TextStyle(fontSize: 16)),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      if (_activeFilters.isNotEmpty) ...[
                        SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            itemCount: _activeFilters.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              final chip = _activeFilters[i];
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF9C5B43),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      chip['label'],
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () {
                                        if (chip['type'] == 'sort') {
                                          setState(() {
                                            _selectedSort = null;
                                          });
                                          _applyFiltersAndOpenSearch(_getCurrentFilters());
                                        } else {
                                          _removeFilterChip(chip);
                                        }
                                      },
                                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      
                      if (_isSearching || _isFiltered) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            children: [
                              const Text('Výsledky:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              const Spacer(),
                            ],
                          ),
                        ),
                        if (_isSearching && _searchResults.isNotEmpty) ...[
                          ..._searchResults.map((cafe) => _CafeListItem(cafe: cafe)),
                        ] else if (_isSearching && _searchResults.isEmpty && _searchController.text.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Center(
                              child: Text(
                                'Žiadne kaviarne neboli nájdené',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        ] else if (_isFiltered && _filteredCafes.isNotEmpty) ...[
                          ..._filteredCafes.map((cafe) => _CafeListItem(cafe: cafe)),
                        ] else if (_isFiltered && _filteredCafes.isEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Center(
                              child: Text(
                                'Žiadne kaviarne neboli nájdené',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      ],
                      
                      if (!_isSearching && !_isFiltered) ...[
                        // --- Pôvodný layout s karuselmi ---
                        const SectionTitle('Populárne nápoje', isLarge: true),
                        DrinkCarousel(
                          drinks: _drinks,
                          onDrinkTap: _onDrinkTap,
                        ),
                        const SizedBox(height: 16),
                        const Row(
                          children: [
                            Expanded(
                              child: SectionTitle('Kaviarne v okolí', isLarge: true),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Odstránené zobrazovanie sortu v texte
                          ],
                        ),
                        if (_cafes.isEmpty)
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
                          CafeCarousel(cafes: _cafes, itemWidth: 200, itemHeight: 140),
                        const SizedBox(height: 16),
                        const SectionTitle('Niečo pod zub', isLarge: true),
                        FoodCarousel(
                          foods: _foods,
                          onFoodTap: _onFoodTap,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
        if (_showCafeSheet && _selectedCafe != null)
          GestureDetector(
            onTap: _closeCafeSheet,
            child: Container(
              color: Colors.black.withOpacity(0.2),
              width: double.infinity,
              height: double.infinity,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: CafeInfoBottomSheet(
                  cafe: _selectedCafe!,
                  onClose: _closeCafeSheet,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CafeListItem extends StatelessWidget {
  final Cafe cafe;

  const _CafeListItem({required this.cafe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CafeDetailPage(cafe: cafe),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: _buildCafeImage(cafe),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              cafe.name,
                              style: AppTextStyles.bold12,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppUtils.formatDistance(cafe.distanceKm),
                            style: AppTextStyles.regular12,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SvgPicture.asset(
                                'assets/icons/recenzieHviezdaPlna.svg',
                                width: 16,
                                height: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                cafe.rating.toStringAsFixed(1),
                                style: AppTextStyles.regular12,
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              SvgPicture.asset(
                                'assets/icons/parkinghnede.svg',
                                width: 16,
                                height: 16,
                              ),
                              const SizedBox(width: 4),
                              SvgPicture.asset(
                                'assets/icons/menuhnede.svg',
                                width: 16,
                                height: 16,
                              ),
                              const SizedBox(width: 4),
                              SvgPicture.asset(
                                'assets/icons/wifihnede.svg',
                                width: 16,
                                height: 16,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCafeImage(Cafe cafe) {
    try {
      // Ak nemáme foto_url, zobrazíme fallback ikonu
      if (cafe.foto_url.isEmpty) {
        return Container(
          width: 80,
          height: 80,
          color: AppColors.grey,
          child: const Icon(
            Icons.local_cafe,
            color: Colors.white70,
            size: 32,
          ),
        );
      }

      // Skontrolujeme, či je to Google Places API URL
      final isGooglePlacesUrl = cafe.foto_url.contains('maps.googleapis.com') || 
                                cafe.foto_url.contains('photoreference');

      // Zobrazíme obrázok z Firebase s error handlingom
      return Image.network(
        cafe.foto_url,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Chyba pri načítaní obrázka pre kaviareň ${cafe.name}: $error');
          
          // Ak je to Google Places API chyba, zobrazíme špeciálnu ikonu
          if (isGooglePlacesUrl) {
            return Container(
              width: 80,
              height: 80,
              color: AppColors.grey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.photo_library_outlined,
                    color: Colors.white70,
                    size: 24,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Foto nedostupné',
                    style: TextStyle(color: Colors.white70, fontSize: 8),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          
          // Pre iné chyby zobrazíme generickú ikonu
          return Container(
            width: 80,
            height: 80,
            color: AppColors.grey,
            child: const Icon(
              Icons.image_not_supported,
              color: Colors.white70,
              size: 32,
            ),
          );
        },
      );
    } catch (e) {
      print('Chyba pri načítaní obrázku kaviarne: $e');
      return Container(
        width: 80,
        height: 80,
        color: AppColors.grey,
        child: const Icon(
          Icons.image_not_supported,
          color: Colors.white70,
          size: 32,
        ),
      );
    }
  }
}

// ------------------- Favorites Page -------------------
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});
  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final FirebaseService _firebaseService = FirebaseService();

  void _showInfoDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _InfoDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Horný rad s nadpisom a ikonou
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Obľúbené', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 26),
                  onPressed: _showInfoDialog,
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<FavoriteItem>>(
              stream: _firebaseService.getFavoritesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Chyba: ${snapshot.error}'),
                  );
                }
                
                final favorites = snapshot.data ?? [];
                
                if (favorites.isEmpty) {
                  return const Center(
                    child: Text(
                      'Žiadne obľúbené položky',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: favorites.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final fav = favorites[i];
                    return FutureBuilder<Cafe?>(
                      future: _firebaseService.getCafeById(fav.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final cafe = snapshot.data;
                        Future<String> getAddress() async {
                          if (cafe != null && cafe.address != null && cafe.address!.trim().isNotEmpty) {
                            return cafe.address!;
                          }
                          if (fav.address != null && fav.address!.trim().isNotEmpty) {
                            return fav.address!;
                          }
                          if (cafe != null) {
                            try {
                              final placemarks = await placemarkFromCoordinates(cafe.latitude, cafe.longitude, localeIdentifier: 'sk');
                              if (placemarks.isNotEmpty) {
                                final p = placemarks.first;
                                String street = p.street ?? '';
                                String number = p.subThoroughfare ?? '';
                                String result = street;
                                if (street.isNotEmpty && number.isNotEmpty) {
                                  result = '$street $number';
                                } else if (street.isEmpty && number.isNotEmpty) {
                                  result = number;
                                }
                                return result.isNotEmpty ? result : 'Adresa nie je dostupná';
                              }
                            } catch (e) {
                              // ignore
                            }
                          }
                          return 'Adresa nie je dostupná';
                        }
                        return FutureBuilder<String>(
                          future: getAddress(),
                          builder: (context, addressSnapshot) {
                            final address = addressSnapshot.data ?? 'Adresa nie je dostupná';
                            // Formátujeme dátum uloženia
                            String formattedDate = 'Neznámy dátum';
                            if (fav.savedAt != null) {
                              final now = DateTime.now();
                              final savedDate = fav.savedAt!;
                              final difference = now.difference(savedDate);
                              if (difference.inDays == 0) {
                                formattedDate = 'Dnes';
                              } else if (difference.inDays == 1) {
                                formattedDate = 'Včera';
                              } else if (difference.inDays < 7) {
                                formattedDate = 'Pred ${difference.inDays} dňami';
                              } else {
                                formattedDate = '${savedDate.day}. ${_getMonthName(savedDate.month)}';
                              }
                            }
                            return _FavoriteCafeItem(
                              imageUrl: cafe?.foto_url ?? fav.imageUrl,
                              name: fav.name,
                              address: address,
                              date: formattedDate,
                              review: null,
                              rating: cafe?.rating ?? 0.0,
                              cafeId: fav.id,
                              note: fav.note,
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'január';
      case 2: return 'február';
      case 3: return 'marec';
      case 4: return 'apríl';
      case 5: return 'máj';
      case 6: return 'jún';
      case 7: return 'júl';
      case 8: return 'august';
      case 9: return 'september';
      case 10: return 'október';
      case 11: return 'november';
      case 12: return 'december';
      default: return 'mesiac';
    }
  }
}

class _FavoriteCafeItem extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final String address;
  final String date;
  final String? review;
  final double rating;
  final String? cafeId; // Firestore ID kaviarne
  final String? note;
  const _FavoriteCafeItem({this.imageUrl, required this.name, required this.address, required this.date, this.review, required this.rating, this.cafeId, this.note});

  bool _isNetworkImage(String? url) {
    return url != null && url.startsWith('http');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            if (cafeId != null) {
              final firebaseService = FirebaseService();
              final loadedCafe = await firebaseService.getCafeById(cafeId!);
              if (loadedCafe != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CafeDetailPage(cafe: loadedCafe),
                  ),
                );
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Horný rad: obrázok + informácie
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mini obrázok
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildFavoriteCafeImage(imageUrl),
                    ),
                    const SizedBox(width: 12),
                    // Informácie: názov, adresa, recenzie
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Názov a recenzia v jednom riadku
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  name.length > 4 ? '${name.substring(0, name.length - 4)}...' : name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              FutureBuilder<List<Review>>(
                                future: FirebaseService().getReviews(cafeId ?? ''),
                                builder: (context, snapshot) {
                                  double averageRating = 0.0;
                                  int reviewCount = 0;
                                  
                                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                    final reviews = snapshot.data!;
                                    reviewCount = reviews.length;
                                    final totalRating = reviews.fold(0, (sum, review) => sum + review.rating);
                                    averageRating = totalRating / reviewCount;
                                  } else {
                                    averageRating = rating; // fallback na pôvodný rating
                                  }
                                  
                                  return Row(
                                    children: [
                                      SvgPicture.asset(
                                        'assets/icons/recenzieHviezdaPlna.svg',
                                        width: 16,
                                        height: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        averageRating.toStringAsFixed(1),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFD2691E)),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(' ($reviewCount)', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          // Adresa
                          Text(
                            (address != null && address.trim().isNotEmpty)
                              ? address
                              : 'Adresa nie je dostupná',
                            style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Poznámka na celú šírku
                if (note != null && note!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      await _showNoteDialog(context, cafeId!, note!);
                    },
                    child: Text(
                      note!,
                      style: const TextStyle(color: Colors.black87, fontSize: 13),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showNoteDialog(BuildContext context, String cafeId, String initialNote) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NoteSheet(
        initialNote: initialNote,
        onSave: (note) async {
          final firebaseService = FirebaseService();
          // Načítaj existujúci FavoriteItem
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final doc = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('favorites')
                .doc(cafeId)
                .get();
            if (doc.exists) {
              final data = doc.data()!;
              final fav = FavoriteItem.fromJson(data);
              final updated = FavoriteItem(
                type: fav.type,
                id: fav.id,
                name: fav.name,
                imageUrl: fav.imageUrl,
                note: note,
              );
              await firebaseService.addToFavorites(updated);
            }
          }
          Navigator.of(context).pop(note);
        },
      ),
    );
    if (result != null) {
      // Po uložení sa UI automaticky refreshne cez StreamBuilder
    }
  }

  Widget _buildFavoriteCafeImage(String? imageUrl) {
    try {
      // Ak nemáme imageUrl, zobrazíme fallback ikonu
      if (imageUrl == null || imageUrl.isEmpty || !_isNetworkImage(imageUrl)) {
        return Container(
          width: 54,
          height: 54,
          color: Colors.black12,
          child: const Icon(
            Icons.local_cafe,
            color: Colors.brown,
            size: 24,
          ),
        );
      }

      // Skontrolujeme, či je to Google Places API URL
      final isGooglePlacesUrl = imageUrl.contains('maps.googleapis.com') || 
                                imageUrl.contains('photoreference');

      // Zobrazíme obrázok z Firebase s error handlingom
      return Image.network(
        imageUrl,
        width: 54,
        height: 54,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Chyba pri načítaní obrázka pre obľúbenú kaviareň: $error');
          
          // Ak je to Google Places API chyba, zobrazíme špeciálnu ikonu
          if (isGooglePlacesUrl) {
            return Container(
              width: 54,
              height: 54,
              color: Colors.black12,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.photo_library_outlined,
                    color: Colors.brown,
                    size: 20,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Foto nedostupné',
                    style: TextStyle(color: Colors.brown, fontSize: 8),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          
          // Pre iné chyby zobrazíme generickú ikonu
          return Container(
            width: 54,
            height: 54,
            color: Colors.black12,
            child: const Icon(
              Icons.local_cafe,
              color: Colors.brown,
              size: 24,
            ),
          );
        },
      );
    } catch (e) {
      print('Chyba pri načítaní obrázku obľúbenej kaviarne: $e');
      return Container(
        width: 54,
        height: 54,
        color: Colors.black12,
        child: const Icon(
          Icons.local_cafe,
          color: Colors.brown,
          size: 24,
        ),
      );
    }
  }
}

// ------------------- Profile Page -------------------
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  String _userName = 'Používateľ';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      print('=== NAČÍTAVANIE ÚDAJOV POUŽÍVATEĽA ===');
      final user = FirebaseAuth.instance.currentUser;
      print('Aktuálny používateľ: ${user?.uid}');
      
      if (user != null) {
        // Najprv skúsime načítať meno lokálne
        print('Načítavam meno lokálne...');
        final localName = await _authService.getLocalUserName();
        print('Lokálne meno: "$localName"');
        
        if (localName != null && localName.isNotEmpty) {
          setState(() {
            _userName = localName;
            _isLoading = false;
          });
          print('Meno nastavené z lokálneho úložiska: "$_userName"');
        } else {
          // Ak nemáme lokálne meno, skúsime z Firestore
          print('Lokálne meno neexistuje, načítavam z Firestore...');
          final firestoreName = await _authService.getUserName(user.uid);
          print('Firestore meno: "$firestoreName"');
          
          if (firestoreName != null && firestoreName.isNotEmpty) {
            // Uložíme do lokálneho úložiska
            await SharedPreferencesService.saveUserName(firestoreName);
            setState(() {
              _userName = firestoreName;
              _isLoading = false;
            });
            print('Meno načítané z Firestore a uložené lokálne: "$_userName"');
          } else {
            // Používateľ nemá meno ani lokálne ani v Firestore
            print('Používateľ nemá meno nastavené');
            setState(() {
              _userName = 'Používateľ';
              _isLoading = false;
            });
          }
        }
      } else {
        print('Používateľ nie je prihlásený');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Chyba pri načítaní údajov používateľa: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveName(String newName) async {
    try {
      print('=== ULOŽENIE MENA ===');
      print('Nové meno: "$newName"');
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('Ukladám meno pre používateľa: ${user.uid}');
        
        // Aktualizujeme meno lokálne aj v Firestore
        await _authService.updateUserName(user.uid, newName);
        print('Meno uložené lokálne aj v Firestore');
        
        // Aktualizujeme UI
        setState(() {
          _userName = newName;
        });
        print('UI aktualizované, nové meno: "$_userName"');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meno bolo úspešne aktualizované')),
        );
      }
    } catch (e) {
      print('Chyba pri aktualizácii mena: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chyba pri aktualizácii mena: $e')),
      );
    }
  }

  Future<void> _editName() async {
    final currentName = (_userName.isEmpty || _userName == 'Používateľ') ? '' : _userName;
    final TextEditingController nameController = TextEditingController(text: currentName);

    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Upraviť meno'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Celé meno',
              hintText: 'Meno a Priezvisko',
            ),
            autofocus: true,
            onSubmitted: (value) async {
              final newName = value.trim();
              if (newName.isNotEmpty) {
                await _saveName(newName);
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Zrušiť'),
            ),
            TextButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  await _saveName(newName);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Meno nemôže byť prázdne')),
                  );
                }
              },
              child: const Text('Uložiť'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    bool showReauth = true;
    bool isLoading = false;
    String? errorText;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Zmeniť heslo'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (user == null) ...[
                    const Text('Nie ste prihlásený. Zadajte e-mail pre reset hesla.'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: currentPasswordController,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ] else ...[
                    TextField(
                      controller: currentPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'Aktuálne heslo',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'Nové heslo',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'Potvrď nové heslo',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                  ],
                  if (errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(errorText!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Zrušiť'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() => isLoading = true);
                          if (user == null) {
                            // Reset hesla cez email
                            final email = currentPasswordController.text.trim();
                            if (email.isEmpty) {
                              setState(() {
                                errorText = 'Zadajte e-mail.';
                                isLoading = false;
                              });
                              return;
                            }
                            try {
                              await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                              if (context.mounted) Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('E-mail na obnovenie hesla bol odoslaný.')),
                              );
                            } on FirebaseAuthException catch (e) {
                              setState(() {
                                errorText = e.message;
                                isLoading = false;
                              });
                            }
                            return;
                          }
                          final newPassword = newPasswordController.text.trim();
                          final confirmPassword = confirmPasswordController.text.trim();
                          final currentPassword = currentPasswordController.text.trim();
                          if (currentPassword.isEmpty) {
                            setState(() {
                              errorText = 'Zadajte aktuálne heslo.';
                              isLoading = false;
                            });
                            return;
                          }
                          if (newPassword.isEmpty) {
                            setState(() {
                              errorText = 'Zadajte nové heslo.';
                              isLoading = false;
                            });
                            return;
                          }
                          if (confirmPassword.isEmpty) {
                            setState(() {
                              errorText = 'Potvrďte nové heslo.';
                              isLoading = false;
                            });
                            return;
                          }
                          if (newPassword != confirmPassword) {
                            setState(() {
                              errorText = 'Nové heslá sa nezhodujú.';
                              isLoading = false;
                            });
                            return;
                          }
                          try {
                            final credential = EmailAuthProvider.credential(
                              email: user.email!,
                              password: currentPassword,
                            );
                            await user.reauthenticateWithCredential(credential);
                            await user.updatePassword(newPassword);
                            if (context.mounted) Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Heslo bolo úspešne zmenené.')),
                            );
                          } on FirebaseAuthException catch (e) {
                            setState(() {
                              errorText = e.message;
                              isLoading = false;
                            });
                          }
                        },
                  child: isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(user == null ? 'Odoslať reset' : 'Zmeniť heslo'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';

    if (_isLoading) {
      return const SafeArea(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                (_userName.isEmpty || _userName == 'Používateľ') ? 'Ahoj!' : 'Ahoj, $_userName', 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 32)
              ),
              // const SizedBox(height: 4),
              // Text(email, style: const TextStyle(color: Colors.black54, fontSize: 16)),
              const SizedBox(height: 24),
              const Text('Profil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              _ProfileRow(
                icon: SizedBox(
                  width: 28,
                  height: 28,
                  child: SvgPicture.asset('assets/icons/userEmpty.svg'),
                ),
                text: (_userName.isEmpty || _userName == 'Používateľ') ? 'Nastaviť meno' : _userName,
                onEdit: _editName,
              ),
              const SizedBox(height: 8),
              _ProfileRow(
                icon: SizedBox(
                  width: 28,
                  height: 28,
                  child: SvgPicture.asset('assets/icons/mail.svg'),
                ),
                text: email,
                onEdit: () {},
                showEdit: true,
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 18),
              const Text('Bezpečnosť', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              _SimpleRow(
                icon: SizedBox(
                  width: 28,
                  height: 28,
                  child: SvgPicture.asset('assets/icons/Lock.svg'),
                ), 
                text: 'Zmeniť heslo',
                onTap: _showChangePasswordDialog,
              ),
              const Divider(),
              _SimpleRow(
                icon: SizedBox(
                  width: 28,
                  height: 28,
                  child: SvgPicture.asset('assets/icons/sukromieIcon.svg'),
                ),
                text: 'Súkromie',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PrivacyScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text('Iné', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              _SimpleRow(
                icon: SizedBox(
                  width: 28,
                  height: 28,
                  child: SvgPicture.asset('assets/icons/infoIcon.svg'),
                ), 
                text: 'Zistiť viac',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const InfoScreen(),
                    ),
                  );
                },
              ),
              const Divider(),
              GestureDetector(
                onTap: () => _logout(context),
                child: _SimpleRow(
                  icon: SizedBox(
                    width: 28,
                    height: 28,
                    child: SvgPicture.asset('assets/icons/Log_Out.svg'),
                  ), 
                  text: 'Log out'
                ),
              ),
              const Divider(),
              GestureDetector(
                onTap: () => _deleteAccount(context),
                child: _SimpleRow(
                  icon: SizedBox(
                    width: 28,
                    height: 28,
                    child: SvgPicture.asset('assets/icons/userdelete.svg'),
                  ), 
                  text: 'Delete account'
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await _authService.signOut();
      // Navigácia sa automaticky spracuje cez AuthWrapper
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chyba pri odhlásení: $e')),
      );
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    // Najprv zobrazíme dialóg na zadanie hesla
    final TextEditingController passwordController = TextEditingController();
    final bool? passwordOk = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Zadajte heslo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pre vymazanie účtu je potrebné zadať vaše aktuálne heslo.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Heslo',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                autofocus: true,
                onSubmitted: (value) async {
                  if (value.isNotEmpty) {
                    Navigator.of(context).pop(true);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Zrušiť'),
            ),
            TextButton(
              onPressed: () async {
                if (passwordController.text.isNotEmpty) {
                  Navigator.of(context).pop(true);
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Pokračovať'),
            ),
          ],
        );
      },
    );

    if (passwordOk == true && passwordController.text.isNotEmpty) {
      // Potvrdzovací dialóg naozajstné vymazanie
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Vymazať účet'),
            content: const Text(
              'Naozaj chcete vymazať svoj účet? Táto akcia je nezvratná a vymaže všetky vaše údaje vrátane obľúbených kaviarní.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Zrušiť'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Vymazať účet'),
              ),
            ],
          );
        },
      );

      if (confirm == true) {
        try {
          // Zobrazíme loading indikátor
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return const AlertDialog(
                content: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text('Vymazávam účet...'),
                  ],
                ),
              );
            },
          );

          await _authService.reAuthenticateAndDeleteAccount(passwordController.text);
          
          // Zatvoríme loading dialóg
          if (context.mounted) {
            Navigator.of(context).pop();
          }
          
          // Navigácia sa automaticky spracuje cez AuthWrapper
        } catch (e) {
          // Zatvoríme loading dialóg
          if (context.mounted) {
            Navigator.of(context).pop();
          }
          
          // Ak prvá metóda zlyhá, skúsime alternatívnu
          if (e.toString().contains('PigeonUserDetails') || 
              e.toString().contains('type cast')) {
            try {
              // Zobrazíme nový loading indikátor
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return const AlertDialog(
                    content: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Skúšam alternatívnu metódu...'),
                      ],
                    ),
                  );
                },
              );
              
              await _authService.alternativeReAuthenticateAndDeleteAccount(passwordController.text);
              
              // Zatvoríme loading dialóg
              if (context.mounted) {
                Navigator.of(context).pop();
              }
              
              // Navigácia sa automaticky spracuje cez AuthWrapper
              return;
            } catch (alternativeError) {
              // Zatvoríme loading dialóg
              if (context.mounted) {
                Navigator.of(context).pop();
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Chyba pri vymazávaní účtu (alternatívna metóda): $alternativeError')),
              );
            }
          } else {
            // Ak re-autentifikácia alebo vymazanie účtu zlyhá, zobraz len chybovú hlášku
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Chyba pri vymazávaní účtu: $e')),
            );
          }
        }
      }
    }
  }
}

class _ProfileRow extends StatelessWidget {
  final Widget icon;
  final String text;
  final VoidCallback? onEdit;
  final bool showEdit;
  const _ProfileRow({required this.icon, required this.text, this.onEdit, this.showEdit = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        icon,
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 16)),
        ),
        if (showEdit)
          GestureDetector(
            onTap: onEdit,
            child: const Text('Upraviť', style: TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.w500)),
          ),
      ],
    );
  }
}

class _SimpleRow extends StatelessWidget {
  final Widget icon;
  final String text;
  final VoidCallback? onTap;
  const _SimpleRow({required this.icon, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: row,
      );
    } else {
      return row;
    }
  }
}

// Vytvorím nový widget _LocationPickerSheet
class _LocationPickerSheet extends StatefulWidget {
  final List<String> citySuggestions;
  final ValueChanged<String> onCitySelected;
  const _LocationPickerSheet({required this.citySuggestions, required this.onCitySelected});

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  String _search = '';
  late List<String> _filteredCities;

  @override
  void initState() {
    super.initState();
    _filteredCities = widget.citySuggestions;
  }

  void _onSearchChanged(String value) {
    setState(() {
      _search = value;
      _filteredCities = widget.citySuggestions
          .where((city) => city.toLowerCase().contains(_search.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Kam to bude?', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            autofocus: true,
            style: TextStyle(color: Colors.black),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search, color: Colors.black),
              hintText: 'Zadaj lokalitu',
              hintStyle: TextStyle(color: Colors.grey),
              filled: true,
              fillColor: AppColors.grey,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
            ),
            onChanged: _onSearchChanged,
            onSubmitted: (value) {
              if (value.isNotEmpty) widget.onCitySelected(value);
            },
          ),
          const SizedBox(height: 16),
          ..._filteredCities.take(8).map((city) => ListTile(
                leading: Icon(Icons.location_on_outlined, color: Colors.black),
                title: Text(city, style: TextStyle(color: Colors.black)),
                onTap: () => widget.onCitySelected(city),
              )),
        ],
      ),
    );
  }
}

// Vytvorím nový widget _NoteSheet
class _NoteSheet extends StatefulWidget {
  final String initialNote;
  final Function(String) onSave;
  const _NoteSheet({required this.initialNote, required this.onSave});

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  late TextEditingController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final note = _controller.text.trim();
    setState(() => _isLoading = true);
    
    try {
      await widget.onSave(note);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Poznámka k obľúbenej kaviarni', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 5,
            style: TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: 'Sem napíš svoju poznámku...',
              hintStyle: TextStyle(color: Colors.grey),
              filled: true,
              fillColor: AppColors.grey,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Zrušiť', style: TextStyle(color: Colors.grey)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveNote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9C5B43),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Uložiť'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapView extends StatefulWidget {
  final Position? currentPosition;
  final List<Cafe> cafes;
  final void Function(Cafe)? onCafeSelected;
  final VoidCallback? onMapTap;
  final double sheetExtent;
  const _MapView({
    this.currentPosition, 
    required this.cafes, 
    this.onCafeSelected,
    this.onMapTap,
    required this.sheetExtent,
  });

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  String? _mapStyle;
  BitmapDescriptor? _customMarkerIcon;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(48.1486, 17.1077), // Bratislava
    zoom: 15.0,
  );

  @override
  void initState() {
    super.initState();
    _loadCustomMarkerIcon();
    _loadMapStyle();
  }

  double get _mapHeight {
    try {
      final screenHeight = MediaQuery.of(context).size.height;
      final sheetHeight = screenHeight * widget.sheetExtent;
      final googleLogoPadding = 40.0;
      final height = screenHeight - sheetHeight + googleLogoPadding;
      return height < 0 ? 0 : height;
    } catch (e) {
      print('❌ Chyba pri výpočte výšky mapy: $e');
      return 300.0; // Fallback výška
    }
  }

  LatLng get _mapCenter {
    try {
      if (widget.currentPosition != null) {
        return LatLng(widget.currentPosition!.latitude, widget.currentPosition!.longitude);
      }
      return _initialPosition.target;
    } catch (e) {
      print('❌ Chyba pri získavaní centra mapy: $e');
      return _initialPosition.target;
    }
  }

  Future<void> _loadCustomMarkerIcon() async {
    try {
      _customMarkerIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(96, 64)),
        'assets/icons/kavamark.png',
      );
      print('✅ Custom marker ikona úspešne načítaná');
      _updateMarkers();
    } catch (e) {
      print('❌ Chyba pri načítaní custom marker ikony: $e');
      print('Používam default marker ikonu');
      _customMarkerIcon = BitmapDescriptor.defaultMarker;
      _updateMarkers();
    }
  }

  Future<void> _loadMapStyle() async {
    try {
      final styleString = await rootBundle.loadString('assets/map_style.json');
      setState(() {
        _mapStyle = styleString;
      });
      print('✅ Mapový štýl úspešne načítaný');
    } catch (e) {
      print('❌ Chyba pri načítaní mapového štýlu: $e');
      print('Používam default mapový štýl');
    }
  }

  @override
  void didUpdateWidget(covariant _MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cafes != oldWidget.cafes) {
      try {
        _updateMarkers();
      } catch (e) {
        print('❌ Chyba pri aktualizácii markerov v didUpdateWidget: $e');
      }
    }
    if (widget.currentPosition != null && widget.currentPosition != oldWidget.currentPosition) {
      try {
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(widget.currentPosition!.latitude, widget.currentPosition!.longitude),
              zoom: 15.0,
            ),
          ),
        );
        print('✅ Kamera úspešne presunutá na novú polohu');
      } catch (e) {
        print('❌ Chyba pri presúvaní kamery na novú polohu: $e');
      }
    }
  }

  void _updateMarkers() {
    try {
      setState(() {
        _markers = widget.cafes.map((cafe) {
          return Marker(
            markerId: MarkerId(cafe.id),
            position: LatLng(cafe.latitude, cafe.longitude),
            icon: _customMarkerIcon ?? BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(title: cafe.name),
            onTap: () {
              if (widget.onCafeSelected != null) {
                widget.onCafeSelected!(cafe);
              }
            },
          );
        }).toSet();
      });
      print('✅ Markery úspešne aktualizované: ${_markers.length} markerov');
    } catch (e) {
      print('❌ Chyba pri aktualizácii markerov: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      if (widget.sheetExtent >= 0.99) {
        return const SizedBox.shrink();
      }
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: _mapHeight,
        child: Padding(
          padding: EdgeInsets.only(bottom: 40),
          child: GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              
              if (_mapStyle != null) {
                try {
                  controller.setMapStyle(_mapStyle!);
                  print('✅ Mapový štýl úspešne aplikovaný');
                } catch (e) {
                  print('❌ Chyba pri aplikovaní mapového štýlu: $e');
                }
              }
              
              if (widget.currentPosition != null) {
                try {
                  controller.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: _mapCenter,
                        zoom: 15.0,
                      ),
                    ),
                  );
                  print('✅ Kamera úspešne presunutá na aktuálnu polohu');
                } catch (e) {
                  print('❌ Chyba pri presúvaní kamery: $e');
                }
              }
            },
            onTap: (LatLng position) {
              try {
                if (widget.onMapTap != null) {
                  widget.onMapTap!();
                }
              } catch (e) {
                print('❌ Chyba pri spracovaní tap na mape: $e');
              }
            },
            initialCameraPosition: CameraPosition(
              target: _mapCenter,
              zoom: 15.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            markers: _markers,
          ),
        ),
      );
    } catch (e) {
      print('❌ Chyba pri buildovaní mapy: $e');
      return Container(
        color: AppColors.grey,
        child: const Center(
          child: Text(
            'Chyba pri načítaní mapy',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    try {
      _mapController?.dispose();
      print('✅ Map controller úspešne uvoľnený');
    } catch (e) {
      print('❌ Chyba pri uvoľňovaní map controller: $e');
    }
    super.dispose();
  }
}

// Info dialog pre sekciu obľúbených
class _InfoDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.45,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Nadpis
          const Text(
            'Obľúbené kaviarne',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          // Text
          const Text(
            'Tu si môžete prezrieť vaše obľúbené kaviarne. Všetky kaviarne, ktoré si označíte ako obľúbené, sa zobrazia v tomto zozname pre rýchly prístup.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          // Ďalšie informácie
          const Text(
            'Ako pridať kaviareň do obľúbených:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '• Stlačte ikonu srdiečka pri kaviarni na mape\n'
            '• Alebo stlačte ikonu srdiečka v detailnej stránke kaviarne\n'
            '• Kaviarne môžete aj odstrániť z obľúbených stlačením srdiečka znovu',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
          ],
        ),
      ),
    );
  }
}
