import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models.dart';
import 'dart:convert';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Načíta všetky kaviarne z Firestore kolekcie 'kaviarne'
  Future<List<Cafe>> getCafes() async {
    try {
      print("Načítavam kaviarne z kolekcie 'kaviarne'...");
      final QuerySnapshot querySnapshot = await _firestore.collection('kaviarne').get();
      print("Nájdených ${querySnapshot.docs.length} dokumentov.");

      if (querySnapshot.docs.isEmpty) {
        print("Kolekcia 'kaviarne' je prázdna alebo neexistujú dáta.");
        return [];
      }
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final polohaData = data['poloha'] as Map<String, dynamic>?;

        final lat = (polohaData?['lat'] ?? 0.0).toDouble();
        final lon = (polohaData?['lng'] ?? 0.0).toDouble();
        final fotoUrl = data['foto_url'] ?? '';
        
        print("Spracovávam '${data['nazov']}': Poloha data: $polohaData, Parsed Lat: $lat, Parsed Lon: $lon");
        print("  Foto URL: '$fotoUrl' (dĺžka: ${fotoUrl.length})");
        
        return Cafe(
          id: doc.id,
          name: data['nazov'] ?? '',
          foto_url: fotoUrl,
          rating: (data['rating'] ?? 0.0).toDouble(),
          isFavorite: data['isFavorite'] ?? false,
          latitude: lat,
          longitude: lon,
          address: data['adresa'] ?? data['address'] ?? '',
        );
      }).toList();
    } catch (e) {
      print('Chyba pri načítaní kaviarní: $e');
      print('Skontroluj Firebase Security Rules. Možno blokujú prístup.');
      return [];
    }
  }

  /// Načíta konkrétnu kaviareň podľa ID
  Future<Cafe?> getCafeById(String cafeId) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection('kaviarne').doc(cafeId).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final polohaData = data['poloha'] as Map<String, dynamic>?;
        final fotoUrl = data['foto_url'] ?? '';
        
        print("Načítavam kaviareň ${data['nazov']} s foto_url: '$fotoUrl'");
        
        return Cafe(
          id: doc.id,
          name: data['nazov'] ?? '',
          foto_url: fotoUrl,
          rating: (data['rating'] ?? 0.0).toDouble(),
          isFavorite: data['isFavorite'] ?? false,
          latitude: (polohaData?['lat'] ?? 0.0).toDouble(),
          longitude: (polohaData?['lng'] ?? 0.0).toDouble(),
          address: data['adresa'] ?? data['address'] ?? '',
        );
      }
      return null;
    } catch (e) {
      print('Chyba pri načítaní kaviarne: $e');
      return null;
    }
  }

  /// Načíta kaviarne v reálnom čase (stream)
  Stream<List<Cafe>> getCafesStream() {
    return _firestore.collection('kaviarne').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final polohaData = data['poloha'] as Map<String, dynamic>?;
        final fotoUrl = data['foto_url'] ?? '';
        
        print("Stream: Načítavam kaviareň ${data['nazov']} s foto_url: '$fotoUrl'");
        
        return Cafe(
          id: doc.id,
          name: data['nazov'] ?? '',
          foto_url: fotoUrl,
          rating: (data['rating'] ?? 0.0).toDouble(),
          isFavorite: data['isFavorite'] ?? false,
          latitude: (polohaData?['lat'] ?? 0.0).toDouble(),
          longitude: (polohaData?['lng'] ?? 0.0).toDouble(),
          address: data['adresa'] ?? data['address'] ?? '',
        );
      }).toList();
    });
  }

  /// Načíta kaviarne, ktoré majú v menu_item zadaný nápoj/jedlo
  Future<List<Cafe>> getCafesByMenuItem(String menuItem) async {
    try {
      print("=== FILTROVANIE MENU ===");
      print("Hľadám kaviarne s menu položkou: $menuItem");
      
      // Načítame všetky kaviarne a filtrujeme ich lokálne
      final QuerySnapshot querySnapshot = await _firestore
          .collection('kaviarne')
          .get();
      
      print("Načítavam všetky kaviarne pre filtrovanie...");
      
      final List<Cafe> filteredCafes = [];
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final cafeName = data['nazov'] ?? 'Neznáma kaviareň';
        
        // Hľadáme menu v rôznych možných kľúčoch
        dynamic menuData;
        if (data.containsKey('menu')) {
          menuData = data['menu'];
        } else if (data.containsKey('menu_item')) {
          menuData = data['menu_item'];
        } else if (data.containsKey('menuItems')) {
          menuData = data['menuItems'];
        }
        
        if (menuData != null) {
          print("Kontrolujem kaviareň: $cafeName");
          print("  Menu data typ: ${menuData.runtimeType}");
          print("  Menu data: $menuData");
          
          List<dynamic> menuItems = [];
          
          // Skontrolujeme rôzne možné formáty menu
          if (menuData is List) {
            menuItems = menuData;
          } else if (menuData is String) {
            // Ak je menu string, skúsime ho parsovať ako JSON
            try {
              final parsed = jsonDecode(menuData);
              if (parsed is List) {
                menuItems = parsed;
              }
            } catch (e) {
              print("  Chyba pri parsovaní menu string: $e");
              // Ak sa nepodarí parsovať, skontrolujeme či string obsahuje hľadaný výraz
              if (menuData.toLowerCase().contains(menuItem.toLowerCase())) {
                print("  ✓ Kaviareň '$cafeName' má v menu string: $menuData (obsahuje: $menuItem)");
                final polohaData = data['poloha'] as Map<String, dynamic>?;
                final lat = (polohaData?['lat'] ?? 0.0).toDouble();
                final lon = (polohaData?['lng'] ?? 0.0).toDouble();
                final fotoUrl = data['foto_url'] ?? '';
                
                print("  Vytváram Cafe objekt pre '$cafeName' s foto_url: '$fotoUrl'");
                
                final cafe = Cafe(
                  id: doc.id,
                  name: cafeName,
                  foto_url: fotoUrl,
                  rating: (data['rating'] ?? 0.0).toDouble(),
                  isFavorite: data['isFavorite'] ?? false,
                  latitude: lat,
                  longitude: lon,
                  address: data['adresa'] ?? data['address'] ?? '',
                );
                
                filteredCafes.add(cafe);
              }
              continue;
            }
          }
          
          if (menuItems.isNotEmpty) {
            print("  Menu položky (${menuItems.length}):");
            
            // Skontrolujeme, či kaviareň má zadanú menu položku
            bool hasMenuItem = false;
            for (final item in menuItems) {
              if (item is Map<String, dynamic>) {
                // Skontrolujeme rôzne možné názvy polí pre produkt
                final produkt = item['produkt'] ?? item['nazov'] ?? item['name'] ?? item['title'] ?? '';
                
                if (produkt.isNotEmpty) {
                  print("    Kontrolujem produkt: '$produkt'");
                  if (_matchesCategory(menuItem, produkt)) {
                    hasMenuItem = true;
                    print("    ✓ Kaviareň '$cafeName' má menu položku: $produkt (kategória: $menuItem)");
                    break;
                  }
                }
              } else if (item is String) {
                print("    Kontrolujem string: '$item'");
                if (_matchesCategory(menuItem, item)) {
                  hasMenuItem = true;
                  print("    ✓ Kaviareň '$cafeName' má menu položku: $item (kategória: $menuItem)");
                  break;
                }
              }
            }
            
            if (hasMenuItem) {
              final polohaData = data['poloha'] as Map<String, dynamic>?;
              final lat = (polohaData?['lat'] ?? 0.0).toDouble();
              final lon = (polohaData?['lng'] ?? 0.0).toDouble();
              final fotoUrl = data['foto_url'] ?? '';
              
              print("  Vytváram Cafe objekt pre '$cafeName' s foto_url: '$fotoUrl'");
              
              final cafe = Cafe(
                id: doc.id,
                name: cafeName,
                foto_url: fotoUrl,
                rating: (data['rating'] ?? 0.0).toDouble(),
                isFavorite: data['isFavorite'] ?? false,
                latitude: lat,
                longitude: lon,
                address: data['adresa'] ?? data['address'] ?? '',
              );
              
              filteredCafes.add(cafe);
            }
          }
        }
      }
      
      print("Nájdených ${filteredCafes.length} kaviarní s $menuItem");
      print("=== KONIEC FILTROVANIA ===");
      return filteredCafes;
      
    } catch (e) {
      print('Chyba pri načítaní kaviarní s menu položkou $menuItem: $e');
      return [];
    }
  }

  /// Inteligentne rozpozná, či menu položka patrí do danej kategórie
  bool _matchesCategory(String category, String menuItemName) {
    final lowercaseCategory = category.toLowerCase();
    final lowercaseMenuItemName = menuItemName.toLowerCase();
    
    print("Kontrolujem kategóriu '$category' pre menu položku '$menuItemName'");
    
    switch (lowercaseCategory) {
      case 'káva':
      case 'kava':
        final isCoffee = _isCoffeeDrink(lowercaseMenuItemName);
        if (isCoffee) print("  ✓ Rozpoznané ako káva: $menuItemName");
        return isCoffee;
      case 'matcha':
        final isMatcha = _isMatchaDrink(lowercaseMenuItemName);
        if (isMatcha) print("  ✓ Rozpoznané ako matcha: $menuItemName");
        return isMatcha;
      case 'mojito':
        final isMixed = _isMixedDrink(lowercaseMenuItemName);
        if (isMixed) print("  ✓ Rozpoznané ako miešaný drink: $menuItemName");
        return isMixed;
      case 'limonáda':
      case 'limonada':
        final isLemonade = _isLemonadeDrink(lowercaseMenuItemName);
        if (isLemonade) print("  ✓ Rozpoznané ako limonáda: $menuItemName");
        return isLemonade;
      case 'kombucha':
        final isKombucha = _isKombuchaDrink(lowercaseMenuItemName);
        if (isKombucha) print("  ✓ Rozpoznané ako kombucha: $menuItemName");
        return isKombucha;
      case 'sandwich':
        final isSandwich = _isSandwichFood(lowercaseMenuItemName);
        if (isSandwich) print("  ✓ Rozpoznané ako sandwich: $menuItemName");
        return isSandwich;
      case 'koláče':
      case 'kolace':
        final isCake = _isCakeFood(lowercaseMenuItemName);
        if (isCake) print("  ✓ Rozpoznané ako koláč: $menuItemName");
        return isCake;
      case 'cinnamon rolls':
        final isCinnamonRolls = _isCinnamonRollsFood(lowercaseMenuItemName);
        if (isCinnamonRolls) print("  ✓ Rozpoznané ako cinnamon rolls: $menuItemName");
        return isCinnamonRolls;
      case 'croissant':
        final isCroissant = _isCroissantFood(lowercaseMenuItemName);
        if (isCroissant) print("  ✓ Rozpoznané ako croissant: $menuItemName");
        return isCroissant;
      case 'pistachio':
        final isPistachio = _isPistachioFood(lowercaseMenuItemName);
        if (isPistachio) print("  ✓ Rozpoznané ako pistachio: $menuItemName");
        return isPistachio;
      default:
        // Ak sa kategória nezhoduje s žiadnou predvolenou, hľadáme presný match
        final exactMatch = lowercaseMenuItemName.contains(lowercaseCategory);
        if (exactMatch) print("  ✓ Presný match s '$lowercaseCategory': $menuItemName");
        return exactMatch;
    }
  }

  /// Rozpozná kávové nápoje
  bool _isCoffeeDrink(String name) {
    final coffeeKeywords = [
      'espresso', 'lungo', 'cappuccino', 'latte', 'americano', 'mocha',
      'macchiato', 'flat white', 'ristretto', 'doppio', 'café', 'kava',
      'káva', 'coffee', 'cappucino', 'cappuccino', 'espresso lungo',
      'espresso ristretto', 'café latte', 'café au lait', 'café con leche',
      'filter coffee', 'pour over', 'aeropress', 'chemex', 'v60',
      'french press', 'cold brew', 'iced coffee', 'coffee americano',
      'coffee latte', 'coffee cappuccino', 'coffee espresso'
    ];
    
    return coffeeKeywords.any((keyword) => name.contains(keyword));
  }

  /// Rozpozná matcha nápoje
  bool _isMatchaDrink(String name) {
    final matchaKeywords = [
      'matcha', 'matcha latte', 'matcha tea', 'green tea', 'zelený čaj',
      'zeleny caj', 'matcha green tea', 'matcha powder'
    ];
    
    return matchaKeywords.any((keyword) => name.contains(keyword));
  }

  /// Rozpozná miešané drinky
  bool _isMixedDrink(String name) {
    final mixedDrinkKeywords = [
      'mojito', 'aperol spritz', 'gin tonic', 'gin and tonic', 'vodka tonic',
      'vodka and tonic', 'rum and coke', 'rum coke', 'whiskey sour',
      'margarita', 'daiquiri', 'pina colada', 'bloody mary', 'negroni',
      'old fashioned', 'manhattan', 'martini', 'cosmopolitan', 'long island',
      'cocktail', 'spritz', 'aperol', 'campari', 'prosecco', 'champagne',
      'beer', 'pivo', 'wine', 'víno', 'vodka', 'gin', 'rum', 'whiskey',
      'tequila', 'brandy', 'cognac', 'liqueur', 'schnapps', 'absinthe'
    ];
    
    return mixedDrinkKeywords.any((keyword) => name.contains(keyword));
  }

  /// Rozpozná limonády
  bool _isLemonadeDrink(String name) {
    final lemonadeKeywords = [
      'limonáda', 'limonada', 'lemonade', 'citronáda', 'citronada',
      'fresh lemonade', 'homemade lemonade', 'strawberry lemonade',
      'raspberry lemonade', 'mint lemonade'
    ];
    
    return lemonadeKeywords.any((keyword) => name.contains(keyword));
  }

  /// Rozpozná kombuchu
  bool _isKombuchaDrink(String name) {
    final kombuchaKeywords = [
      'kombucha', 'kombucha tea', 'fermented tea', 'probiotic drink'
    ];
    
    return kombuchaKeywords.any((keyword) => name.contains(keyword));
  }

  /// Rozpozná sendviče
  bool _isSandwichFood(String name) {
    final sandwichKeywords = [
      'sandwich', 'sendvič', 'sendvic', 'panini', 'toast', 'bagel',
      'club sandwich', 'grilled cheese', 'blt', 'tuna sandwich',
      'chicken sandwich', 'veggie sandwich'
    ];
    
    return sandwichKeywords.any((keyword) => name.contains(keyword));
  }

  /// Rozpozná koláče
  bool _isCakeFood(String name) {
    final cakeKeywords = [
      'koláč', 'kolac', 'cake', 'torta', 'torte', 'cheesecake',
      'chocolate cake', 'carrot cake', 'red velvet', 'tiramisu',
      'brownie', 'muffin', 'cupcake', 'pie', 'strudel'
    ];
    
    return cakeKeywords.any((keyword) => name.contains(keyword));
  }

  /// Rozpozná cinnamon rolls
  bool _isCinnamonRollsFood(String name) {
    final cinnamonRollsKeywords = [
      'cinnamon roll', 'cinnamon rolls', 'cinnamon bun', 'cinnamon buns',
      'kanelbulle', 'kanelbullar', 'cinnamon swirl', 'cinnamon pastry'
    ];
    
    return cinnamonRollsKeywords.any((keyword) => name.contains(keyword));
  }

  /// Rozpozná croissanty
  bool _isCroissantFood(String name) {
    final croissantKeywords = [
      'croissant', 'croissants', 'kroasan', 'kroasany', 'pain au chocolat',
      'chocolate croissant', 'almond croissant', 'butter croissant'
    ];
    
    return croissantKeywords.any((keyword) => name.contains(keyword));
  }

  /// Rozpozná pistachio jedlá
  bool _isPistachioFood(String name) {
    final pistachioKeywords = [
      'pistachio', 'pistácie', 'pistacie', 'pistachio cake',
      'pistachio ice cream', 'pistachio pastry', 'pistachio cookie'
    ];
    
    return pistachioKeywords.any((keyword) => name.contains(keyword));
  }

  // --- METÓDY PRE OBLÚBENÉ POLOŽKY ---

  /// Načíta obľúbené položky pre aktuálneho používateľa
  Future<List<FavoriteItem>> getFavorites() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .get();

      return doc.docs.map((doc) {
        final data = doc.data();
        return FavoriteItem.fromJson(data);
      }).toList();
    } catch (e) {
      print('Chyba pri načítaní obľúbených položiek: $e');
      return [];
    }
  }

  /// Stream pre obľúbené položky v reálnom čase
  Stream<List<FavoriteItem>> getFavoritesStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return FavoriteItem.fromJson(data);
          }).toList();
        });
  }

  /// Pridá položku do obľúbených
  Future<void> addToFavorites(FavoriteItem item) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Používateľ nie je prihlásený');

      // Vytvoríme item s aktuálnym dátumom
      final itemWithDate = FavoriteItem(
        type: item.type,
        id: item.id,
        name: item.name,
        imageUrl: item.imageUrl,
        note: item.note,
        address: item.address,
        savedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(item.id)
          .set(itemWithDate.toJson());
    } catch (e) {
      print('Chyba pri pridávaní do obľúbených: $e');
      throw e;
    }
  }

  /// Odstráni položku z obľúbených
  Future<void> removeFromFavorites(String itemId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Používateľ nie je prihlásený');

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(itemId)
          .delete();
    } catch (e) {
      print('Chyba pri odstraňovaní z obľúbených: $e');
      throw e;
    }
  }

  /// Skontroluje, či je položka v obľúbených
  Future<bool> isFavorite(String itemId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(itemId)
          .get();

      return doc.exists;
    } catch (e) {
      print('Chyba pri kontrole obľúbených: $e');
      return false;
    }
  }

  // --- METÓDY PRE MENU A OTVÁRACIE HODINY ---

  /// Načíta menu položky pre kaviareň
  Future<List<MenuItem>> getMenuItems(String cafeId) async {
    try {
      print("Načítavam menu pre kaviareň: $cafeId");
      
      // Načítame dokument kaviarne
      final DocumentSnapshot doc = await _firestore
          .collection('kaviarne')
          .doc(cafeId)
          .get();

      if (!doc.exists) {
        print("Dokument kaviarne $cafeId neexistuje");
        return [];
      }

      final data = doc.data() as Map<String, dynamic>;
      print("Dostupné kľúče v dokumente: ${data.keys.toList()}");
      
      // Špeciálne debugovanie pre kaviareň bfJ85NHm98zlLipUroPe
      if (cafeId == 'bfJ85NHm98zlLipUroPe') {
        print("=== DEBUG PRE KAVIAREŇ bfJ85NHm98zlLipUroPe ===");
        print("Všetky dáta: $data");
        if (data.containsKey('menu_item')) {
          print("Menu item data: ${data['menu_item']}");
        }
        if (data.containsKey('menu')) {
          print("Menu data: ${data['menu']}");
        }
        print("=== KONIEC DEBUG ===");
      }
      
      // Hľadáme menu v rôznych možných kľúčoch
      List<dynamic>? menuData;
      if (data.containsKey('menu')) {
        menuData = data['menu'] as List<dynamic>?;
        print("Našiel som menu pod kľúčom 'menu'");
      } else if (data.containsKey('menu_item')) {
        menuData = data['menu_item'] as List<dynamic>?;
        print("Našiel som menu pod kľúčom 'menu_item'");
      } else if (data.containsKey('menuItems')) {
        menuData = data['menuItems'] as List<dynamic>?;
        print("Našiel som menu pod kľúčom 'menuItems'");
      }

      if (menuData == null || menuData.isEmpty) {
        print("Menu nie je nájdené alebo je prázdne");
        return [];
      }

      print("Načítavam ${menuData.length} menu položiek");
      print("Prvá položka: ${menuData.first}");
      
      return menuData.map((item) {
        if (item is Map<String, dynamic>) {
          print("Spracovávam menu položku: $item");
          try {
            final menuItem = MenuItem.fromJson(item);
            print("Úspešne vytvorená MenuItem: ${menuItem.nazov} - ${menuItem.cena}");
            return menuItem;
          } catch (e) {
            print("Chyba pri spracovaní menu položky: $e");
            return null;
          }
        } else {
          print("Neplatný formát menu položky: $item (typ: ${item.runtimeType})");
          return null;
        }
      }).where((item) => item != null).cast<MenuItem>().toList();
      
    } catch (e) {
      print('Chyba pri načítaní menu: $e');
      return [];
    }
  }

  /// Stream pre menu položky v reálnom čase
  Stream<List<MenuItem>> getMenuItemsStream(String cafeId) {
    return _firestore
        .collection('kaviarne')
        .doc(cafeId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            return <MenuItem>[];
          }

          final data = snapshot.data() as Map<String, dynamic>;
          
          // Hľadáme menu v rôznych možných kľúčoch
          List<dynamic>? menuData;
          if (data.containsKey('menu')) {
            menuData = data['menu'] as List<dynamic>?;
          } else if (data.containsKey('menu_item')) {
            menuData = data['menu_item'] as List<dynamic>?;
          } else if (data.containsKey('menuItems')) {
            menuData = data['menuItems'] as List<dynamic>?;
          }

          if (menuData == null || menuData.isEmpty) {
            return <MenuItem>[];
          }

          return menuData.map((item) {
            if (item is Map<String, dynamic>) {
              return MenuItem.fromJson(item);
            } else {
              return null;
            }
          }).where((item) => item != null).cast<MenuItem>().toList();
        });
  }

  /// Načíta otváracie hodiny pre kaviareň
  Future<List<OpeningHours>> getOpeningHours(String cafeId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('kaviarne')
          .doc(cafeId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        print('=== DEBUG: Dáta kaviarne $cafeId ===');
        print('Všetky kľúče: ${data.keys.toList()}');
        
        // Skúsime rôzne možné názvy polí pre otváracie hodiny
        dynamic otvaracieHodinyRaw;
        if (data.containsKey('otvaracie_hodiny')) {
          otvaracieHodinyRaw = data['otvaracie_hodiny'];
        } else if (data.containsKey('otvaracieHodiny')) {
          otvaracieHodinyRaw = data['otvaracieHodiny'];
        } else if (data.containsKey('opening_hours')) {
          otvaracieHodinyRaw = data['opening_hours'];
        }

        if (otvaracieHodinyRaw != null) {
          // Ak je to List<String>
          if (otvaracieHodinyRaw is List) {
            final List<String> zoznam = otvaracieHodinyRaw.cast<String>();
            return zoznam.map((line) {
              final parts = line.split(":");
              if (parts.length >= 2) {
                final den = parts[0].trim();
                final hodiny = parts.sublist(1).join(":").trim();
                return OpeningHours(den: _skratkaDna(den), hodiny: hodiny);
              } else {
                return OpeningHours(den: line, hodiny: '');
              }
            }).toList();
          }
          // Ak je to Map<String, dynamic> (pôvodný fallback)
          if (otvaracieHodinyRaw is Map<String, dynamic>) {
            final otvaracieHodiny = otvaracieHodinyRaw;
            return [
              OpeningHours(den: 'Po', hodiny: _getHodinyForDen(otvaracieHodiny, ['po', 'pondelok', 'monday', '1'])),
              OpeningHours(den: 'Ut', hodiny: _getHodinyForDen(otvaracieHodiny, ['ut', 'utorok', 'tuesday', '2'])),
              OpeningHours(den: 'St', hodiny: _getHodinyForDen(otvaracieHodiny, ['st', 'streda', 'wednesday', '3'])),
              OpeningHours(den: 'Št', hodiny: _getHodinyForDen(otvaracieHodiny, ['st', 'stvrtok', 'thursday', '4'])),
              OpeningHours(den: 'Pi', hodiny: _getHodinyForDen(otvaracieHodiny, ['pi', 'piatok', 'friday', '5'])),
              OpeningHours(den: 'So', hodiny: _getHodinyForDen(otvaracieHodiny, ['so', 'sobota', 'saturday', '6'])),
              OpeningHours(den: 'Ne', hodiny: _getHodinyForDen(otvaracieHodiny, ['ne', 'nedela', 'sunday', '0'])),
            ];
          }
        }
      }
      print('Používam fallback otváracie hodiny pre kaviareň $cafeId');
      // Fallback - vráti predvolené hodiny ak nie sú v databáze
      return [
        OpeningHours(den: 'Po', hodiny: '9:00 – 16:15'),
        OpeningHours(den: 'Ut', hodiny: '9:00 – 16:15'),
        OpeningHours(den: 'St', hodiny: '9:00 – 16:15'),
        OpeningHours(den: 'Št', hodiny: '9:00 – 16:15'),
        OpeningHours(den: 'Pi', hodiny: '9:00 – 16:15'),
        OpeningHours(den: 'So', hodiny: '9:00 – 16:15'),
        OpeningHours(den: 'Ne', hodiny: '9:00 – 16:15'),
      ];
    } catch (e) {
      print('Chyba pri načítaní otváracích hodín pre kaviareň $cafeId: $e');
      // Fallback hodiny
      return [
        OpeningHours(den: 'Po', hodiny: '9:00 – 16:15'),
        OpeningHours(den: 'Ut', hodiny: '9:00 – 16:15'),
        OpeningHours(den: 'St', hodiny: '9:00 – 16:15'),
        OpeningHours(den: 'Št', hodiny: '9:00 – 16:15'),
        OpeningHours(den: 'Pi', hodiny: '9:00 – 16:15'),
        OpeningHours(den: 'So', hodiny: '9:00 – 16:15'),
        OpeningHours(den: 'Ne', hodiny: '9:00 – 16:15'),
      ];
    }
  }

  /// Získa aktuálne otváracie hodiny pre dnešný deň
  Future<OpeningHours?> getCurrentDayOpeningHours(String cafeId) async {
    try {
      final allHours = await getOpeningHours(cafeId);
      final now = DateTime.now();
      final currentDay = now.weekday; // 1 = Monday, 7 = Sunday
      
      // Mapovanie dní týždňa
      final dayMapping = {
        'Po': 1, 'Ut': 2, 'St': 3, 'Št': 4, 'Pi': 5, 'So': 6, 'Ne': 7,
        'Pondelok': 1, 'Utorok': 2, 'Streda': 3, 'Štvrtok': 4, 'Piatok': 5, 'Sobota': 6, 'Nedeľa': 7,
        'Monday': 1, 'Tuesday': 2, 'Wednesday': 3, 'Thursday': 4, 'Friday': 5, 'Saturday': 6, 'Sunday': 7,
      };

      for (final hours in allHours) {
        if (dayMapping[hours.den] == currentDay) {
          return hours;
        }
      }
      
      return null;
    } catch (e) {
      print('Chyba pri získavaní aktuálnych otváracích hodín: $e');
      return null;
    }
  }

  String _skratkaDna(String den) {
    switch (den.toLowerCase()) {
      case 'monday': return 'Po';
      case 'tuesday': return 'Ut';
      case 'wednesday': return 'St';
      case 'thursday': return 'Št';
      case 'friday': return 'Pi';
      case 'saturday': return 'So';
      case 'sunday': return 'Ne';
      default: return den;
    }
  }

  /// Pomocná metóda na získanie hodín pre daný deň
  String _getHodinyForDen(Map<String, dynamic> otvaracieHodiny, List<String> possibleKeys) {
    for (String key in possibleKeys) {
      if (otvaracieHodiny.containsKey(key)) {
        final value = otvaracieHodiny[key];
        if (value != null && value.toString().isNotEmpty) {
          return value.toString();
        }
      }
    }
    return 'Zatvorené';
  }

  /// Testovacia metóda pre kaviareň s UID bfJ85NHm98zlLipUroPe
  Future<void> testCafeMenu(String cafeId) async {
    try {
      print("=== TEST KAVIARNE $cafeId ===");
      final doc = await _firestore.collection('kaviarne').doc(cafeId).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        print("Kaviareň: ${data['nazov'] ?? 'Neznáma'}");
        
        // Skontrolujeme všetky možné kľúče pre menu
        final possibleKeys = ['menu', 'menu_item', 'menuItems', 'menu_items'];
        for (final key in possibleKeys) {
          if (data.containsKey(key)) {
            final menuData = data[key];
            print("Kľúč '$key': $menuData (typ: ${menuData.runtimeType})");
          }
        }
        
        // Ak nemá menu, pridáme testovacie
        if (!data.containsKey('menu') && !data.containsKey('menu_item') && !data.containsKey('menuItems')) {
          print("Kaviareň nemá menu - pridávam testovacie dáta...");
          
          final testMenu = [
            {"produkt": "Matcha Latte", "cena": 4.50},
            {"produkt": "Espresso", "cena": 2.50},
            {"produkt": "Cappuccino", "cena": 3.20},
            {"produkt": "Mojito", "cena": 4.90},
            {"produkt": "Limonáda", "cena": 3.80},
          ];
          
          await _firestore.collection('kaviarne').doc(cafeId).update({
            'menu': testMenu,
          });
          
          print("Testovacie menu pridané!");
        }
      } else {
        print("Kaviareň s ID $cafeId neexistuje");
      }
      print("=== KONIEC TESTU ===");
    } catch (e) {
      print("Chyba pri teste kaviarne: $e");
    }
  }

  // --- METÓDY PRE RECENZIE ---

  /// Pridá recenziu pre kaviareň
  Future<void> addReview(Review review) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Používateľ nie je prihlásený');

      await _firestore
          .collection('kaviarne')
          .doc(review.cafeId)
          .collection('reviews')
          .doc(review.id)
          .set(review.toJson());

      print('Recenzia úspešne pridaná: ${review.id}');
    } catch (e) {
      print('Chyba pri pridávaní recenzie: $e');
      throw e;
    }
  }

  /// Načíta recenzie pre kaviareň
  Future<List<Review>> getReviews(String cafeId) async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection('kaviarne')
          .doc(cafeId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Review.fromJson(data);
      }).toList();
    } catch (e) {
      print('Chyba pri načítaní recenzií: $e');
      return [];
    }
  }

  /// Stream pre recenzie v reálnom čase
  Stream<List<Review>> getReviewsStream(String cafeId) {
    return _firestore
        .collection('kaviarne')
        .doc(cafeId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Review.fromJson(data);
      }).toList();
    });
  }


  /// Skontroluje, či používateľ už napísal recenziu pre kaviareň
  Future<bool> hasUserReviewed(String cafeId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final QuerySnapshot querySnapshot = await _firestore
          .collection('kaviarne')
          .doc(cafeId)
          .collection('reviews')
          .where('userId', isEqualTo: user.uid)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Chyba pri kontrole recenzie používateľa: $e');
      return false;
    }
  }
} 