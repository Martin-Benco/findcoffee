import 'package:flutter/material.dart';

void main() {
  runApp(const CoffitApp());
}

class CoffitApp extends StatelessWidget {
  const CoffitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coffit',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
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
        items: const [
          BottomNavigationBarItem(
            icon: SizedBox(width: 24, height: 24, child: DecoratedBox(decoration: BoxDecoration(color: Colors.brown))),
            label: 'Domov',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(width: 24, height: 24, child: DecoratedBox(decoration: BoxDecoration(color: Colors.brown))),
            label: 'Obľúbené',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(width: 24, height: 24, child: DecoratedBox(decoration: BoxDecoration(color: Colors.brown))),
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
  HomeMode _mode = HomeMode.searchMap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Prepínanie režimov
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ModeButton(
                  selected: _mode == HomeMode.search,
                  onTap: () => setState(() => _mode = HomeMode.search),
                  label: 'Search',
                ),
                const SizedBox(width: 16),
                _ModeButton(
                  selected: _mode == HomeMode.searchMap,
                  onTap: () => setState(() => _mode = HomeMode.searchMap),
                  label: 'Search+Map',
                ),
                const SizedBox(width: 16),
                _ModeButton(
                  selected: _mode == HomeMode.map,
                  onTap: () => setState(() => _mode = HomeMode.map),
                  label: 'Map',
                ),
              ],
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                switch (_mode) {
                  case HomeMode.search:
                    return const _SearchView();
                  case HomeMode.searchMap:
                    return const _SearchMapView();
                  case HomeMode.map:
                    return const _MapView();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final String label;
  const _ModeButton({required this.selected, required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: selected ? Colors.brown : Colors.brown[200],
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: selected ? Colors.brown : Colors.brown[200])),
        ],
      ),
    );
  }
}

class _SearchView extends StatelessWidget {
  const _SearchView();
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Vyhľadávanie (bez mapy)', style: TextStyle(fontSize: 18)));
  }
}

class _SearchMapView extends StatelessWidget {
  const _SearchMapView();
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Vyhľadávanie + Mapa (default)', style: TextStyle(fontSize: 18)));
  }
}

class _MapView extends StatelessWidget {
  const _MapView();
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Mapa na celú obrazovku', style: TextStyle(fontSize: 18)));
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
