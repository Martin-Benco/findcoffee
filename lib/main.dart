import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'core/theme/app_text_styles.dart';

void main() {
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
        const _MapView(),
        DraggableScrollableSheet(
          initialChildSize: 0.12, // cca výška search baru
          minChildSize: 0.12,
          maxChildSize: 1.0,
          snap: true,
          snapSizes: const [0.12, 0.5, 1.0],
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
                            const SizedBox(width: 12),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Vyhľadávanie',
                                style: AppTextStyles.regular12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_mode != HomeMode.map) ...[
                      // Tu môžeš pridať ďalší obsah pre režimy searchMap a search
                      Center(
                        child: Text(
                          _mode == HomeMode.searchMap
                              ? 'Režim: Mapa + Vyhľadávanie'
                              : 'Režim: Vyhľadávanie',
                          style: AppTextStyles.regular12,
                        ),
                      ),
                      const SizedBox(height: 400), // Placeholder pre ďalší obsah
                    ] else ...[
                      const SizedBox(height: 600), // Umožní drag aj v režime map
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
  const _MapView();

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;

  // Počiatočná pozícia (Bratislava) - použije sa, kým sa nezíska aktuálna poloha
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(48.1486, 17.1077),
    zoom: 15.0,
  );

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  /// Získa aktuálnu polohu používateľa
  Future<void> _getCurrentLocation() async {
    try {
      // Kontrola povolení
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoading = false);
        return;
      }

      // Získanie aktuálnej polohy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      // Presun kamery na aktuálnu polohu
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 15.0,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        
        // Ak už máme aktuálnu polohu, presunieme kameru
        if (_currentPosition != null) {
          controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                zoom: 15.0,
              ),
            ),
          );
        }
      },
      initialCameraPosition: _currentPosition != null
          ? CameraPosition(
              target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
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
