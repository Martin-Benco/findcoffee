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
import 'core/models.dart';
import 'core/firebase_service.dart';
import 'core/auth_service.dart';
import 'widgets/login_sheet.dart';
import 'widgets/register_sheet.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'widgets/cafe_detail_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Test menu kaviarne
    _firebaseService.testCafeMenu('bfJ85NHm98zlLipUroPe');
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

  final List<Widget> _pages = [];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Vytvoríme pages až po načítaní dát
    if (_pages.isEmpty && !_isLoadingCafes) {
      _pages.addAll([
        HomePage(
          currentPosition: _currentPosition,
          cafes: _cafes,
          firebaseService: _firebaseService,
        ),
        FavoritesPage(),
        ProfilePage(),
      ]);
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
  
  // Mock dáta pre nápoje a jedlá (zatiaľ)
  final List<Drink> _drinks = const [
    Drink(name: 'Matcha', imageUrl: 'assets/images/matcha.jpg'),
    Drink(name: 'Káva', imageUrl: 'assets/images/kava.jpg'),
    Drink(name: 'Mojito', imageUrl: 'assets/images/drinky.jpg'),
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

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.currentPosition;
    _cafes = widget.cafes;
    
    // Test menu kaviarne
    widget.firebaseService.testCafeMenu('bfJ85NHm98zlLipUroPe');
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

    if (newMode != _mode) {
      setState(() {
        if (_mode == HomeMode.search && newMode != HomeMode.search) {
          FocusScope.of(context).unfocus();
        }
        _mode = newMode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Mapa je vždy na pozadí
        _MapView(currentPosition: _currentPosition),

        // Menu button
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/ciernemenu.svg',
                width: 24,
                height: 24,
              ),
            ),
          ),
        ),

        DraggableScrollableSheet(
          controller: _sheetController,
          initialChildSize: 0.75, // cca výška search baru
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
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _mode == HomeMode.search ? 0.0 : 1.0,
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.grey,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        height: _mode == HomeMode.search ? 44 : 48,
                        decoration: BoxDecoration(
                          color: _mode == HomeMode.search ? AppColors.background : AppColors.grey,
                          borderRadius: BorderRadius.circular(12),
                          border: _mode == HomeMode.search
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
                                onTap: _animateSheetToSearch,
                                textAlignVertical: TextAlignVertical.center,
                                decoration: const InputDecoration(
                                  isCollapsed: true,
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
                                    _resetSearchAndFilter();
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
                                onTap: _resetSearchAndFilter,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 16.0),
                                  child: SvgPicture.asset(
                                    'assets/icons/cierneX.svg',
                                    width: 20,
                                    height: 20,
                                  ),
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.only(right: 16.0),
                                child: SvgPicture.asset(
                                  'assets/icons/filterIcon.svg',
                                  width: 24,
                                  height: 24,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (_isSearching || _isFiltered) ...[
                      // --- Nový layout pre výsledky vyhľadávania ---
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: SectionTitle(
                                _isSearching 
                                  ? 'Výsledky vyhľadávania'
                                  : _selectedDrink != null 
                                    ? 'Kaviarne s $_selectedDrink' 
                                    : 'Kaviarne s $_selectedFood'!, 
                                isLarge: true
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isLoadingCafes)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if ((_isSearching && _searchResults.isEmpty) || (_isFiltered && _filteredCafes.isEmpty))
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              _isSearching ? 'Žiadne kaviarne neboli nájdené' : 'Žiadne kaviarne s týmto produktom neboli nájdené',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ...(_isSearching ? _searchResults : _filteredCafes)
                            .map((cafe) => _CafeListItem(cafe: cafe))
                            .toList(),
                      const SizedBox(height: 24),

                    ] else ...[
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
                      if (_mode == HomeMode.search || _mode == HomeMode.searchMap) ...[
                        const SizedBox(height: 16),
                        const SectionTitle('Niečo pod zub', isLarge: true),
                        FoodCarousel(
                          foods: _foods,
                          onFoodTap: _onFoodTap,
                        ),
                        const SizedBox(height: 24),
                      ] else ...[
                        const SizedBox(height: 24),
                      ],
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

class _CafeListItem extends StatelessWidget {
  final Cafe cafe;

  const _CafeListItem({required this.cafe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CafeDetailPage(cafe: cafe),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.network(
                cafe.foto_url,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 80,
                  color: AppColors.grey,
                  child: const Icon(Icons.image_not_supported, color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 80,
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
                          '${cafe.distanceKm.toStringAsFixed(1)} km',
                          style: AppTextStyles.regular12,
                        ),
                      ],
                    ),
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
            ),
          ],
        ),
      ),
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
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});
  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final FirebaseService _firebaseService = FirebaseService();

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
                  onPressed: () {},
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
                    // Mock data pre ukážku (adresu, dátum, hodnotenie, recenziu)
                    final address = fav.name == 'Saint Coffee'
                        ? '6 Apr – Prešov, Luthanskeho 18'
                        : fav.name == 'Pauza Coffee and Cake'
                            ? '8 Apr – Prešov, Popradska 2'
                            : '2 Apr – Prešov, Jogurskeho 15';
                    final date = fav.name == 'Saint Coffee'
                        ? '21 May, 2025'
                        : fav.name == 'Pauza Coffee and Cake'
                            ? '5 April, 2025'
                            : '1 Jun, 2025';
                    final review = fav.name == 'Saint Coffee'
                        ? 'Bolo to skvelé!!!'
                        : fav.name == 'Pauza Coffee and Cake'
                            ? 'Super preso.'
                            : 'Bola som tu v...';
                    final rating = fav.name == 'Saint Coffee'
                        ? 4.7
                        : fav.name == 'Pauza Coffee and Cake'
                            ? 4.9
                            : 4.5;
                    return _FavoriteCafeItem(
                      imageUrl: fav.imageUrl,
                      name: fav.name,
                      address: address,
                      date: date,
                      review: review,
                      rating: rating,
                      cafeId: fav.id, // id je Firestore ID kaviarne
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
}

class _FavoriteCafeItem extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final String address;
  final String date;
  final String review;
  final double rating;
  final String? cafeId; // Firestore ID kaviarne
  const _FavoriteCafeItem({this.imageUrl, required this.name, required this.address, required this.date, required this.review, required this.rating, this.cafeId});

  bool _isNetworkImage(String? url) {
    return url != null && url.startsWith('http');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ľavý stĺpec: obrázok, pod ním dátum a poznámka
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: (imageUrl != null && imageUrl!.isNotEmpty && _isNetworkImage(imageUrl))
                          ? Image.network(imageUrl!, width: 54, height: 54, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 54, height: 54, color: Colors.black12, child: const Icon(Icons.local_cafe, color: Colors.brown)))
                          : Container(width: 54, height: 54, color: Colors.black12, child: const Icon(Icons.local_cafe, color: Colors.brown)),
                    ),
                    const SizedBox(height: 6),
                    Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    SizedBox(
                      width: 54,
                      child: Text(review, style: const TextStyle(color: Colors.black87, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Pravý stĺpec: názov a adresa
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(address, style: const TextStyle(color: Colors.black87, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star_border, color: Color(0xFFD2691E), size: 22),
                        const SizedBox(width: 2),
                        Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFD2691E))),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------- Profile Page -------------------
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<Map<String, dynamic>?> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserData(),
      builder: (context, snapshot) {
        final user = FirebaseAuth.instance.currentUser;
        final email = user?.email ?? '';
        final name = snapshot.data != null && snapshot.data!['name'] != null ? snapshot.data!['name'] as String : 'Používateľ';
        final firstName = name.split(' ').isNotEmpty ? name.split(' ')[0] : name;

        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text('Ahoj, $firstName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 32)),
                  const SizedBox(height: 12),
                  const Text('Profil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  _ProfileRow(
                    icon: SvgPicture.asset('assets/icons/userEmpty.svg', width: 28, height: 28),
                    text: name,
                    onEdit: () {},
                  ),
                  const Divider(height: 1),
                  _ProfileRow(
                    icon: SvgPicture.asset('assets/icons/mail.svg', width: 28, height: 28),
                    text: email,
                    onEdit: () {},
                    showEdit: true,
                  ),
                  const SizedBox(height: 12),
                  // Premium banner
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/Premium.png',
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Personalizácia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Farba', style: TextStyle(fontSize: 16)),
                      const Spacer(),
                      Container(
                        width: 48,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Bezpečnosť', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  _SimpleRow(icon: SvgPicture.asset('assets/icons/Lock.svg', width: 28, height: 28), text: 'Heslo'),
                  const Divider(height: 1),
                  _SimpleRow(icon: SvgPicture.asset('assets/icons/eyehide.svg', width: 28, height: 28), text: 'Súkromie'),
                  const SizedBox(height: 12),
                  const Text('Iné', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  _SimpleRow(icon: SvgPicture.asset('assets/icons/infoIcon.svg', width: 28, height: 28), text: 'Zistiť viac'),
                  const Divider(height: 1),
                  GestureDetector(
                    onTap: () => _logout(context),
                    child: _SimpleRow(icon: SvgPicture.asset('assets/icons/Log_Out.svg', width: 28, height: 28), text: 'Log out'),
                  ),
                  const Divider(height: 1),
                  _SimpleRow(icon: SvgPicture.asset('assets/icons/userdelete.svg', width: 28, height: 28), text: 'Delete account'),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigácia sa automaticky spracuje cez AuthWrapper
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chyba pri odhlásení: $e')),
      );
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
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
      ),
    );
  }
}

class _SimpleRow extends StatelessWidget {
  final Widget icon;
  final String text;
  const _SimpleRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
