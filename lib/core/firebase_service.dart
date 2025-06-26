import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models.dart';

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

        print("Spracovávam '${data['nazov']}': Poloha data: $polohaData, Parsed Lat: $lat, Parsed Lon: $lon");
        
        return Cafe(
          id: doc.id,
          name: data['nazov'] ?? '',
          foto_url: data['foto_url'] ?? '',
          rating: (data['rating'] ?? 0.0).toDouble(),
          isFavorite: data['isFavorite'] ?? false,
          latitude: lat,
          longitude: lon,
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
        
        return Cafe(
          id: doc.id,
          name: data['nazov'] ?? '',
          foto_url: data['foto_url'] ?? '',
          rating: (data['rating'] ?? 0.0).toDouble(),
          isFavorite: data['isFavorite'] ?? false,
          latitude: (polohaData?['lat'] ?? 0.0).toDouble(),
          longitude: (polohaData?['lng'] ?? 0.0).toDouble(),
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
        
        return Cafe(
          id: doc.id,
          name: data['nazov'] ?? '',
          foto_url: data['foto_url'] ?? '',
          rating: (data['rating'] ?? 0.0).toDouble(),
          isFavorite: data['isFavorite'] ?? false,
          latitude: (polohaData?['lat'] ?? 0.0).toDouble(),
          longitude: (polohaData?['lng'] ?? 0.0).toDouble(),
        );
      }).toList();
    });
  }

  /// Načíta kaviarne, ktoré majú v menu_item zadaný nápoj
  Future<List<Cafe>> getCafesByMenuItem(String menuItem) async {
    try {
      print("Hľadám kaviarne s menu_item: $menuItem");
      
      // Hľadáme kaviarne kde menu_item obsahuje zadaný nápoj
      final QuerySnapshot querySnapshot = await _firestore
          .collection('kaviarne')
          .where('menu_item', arrayContains: menuItem)
          .get();
      
      print("Nájdených ${querySnapshot.docs.length} kaviarní s $menuItem");

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final polohaData = data['poloha'] as Map<String, dynamic>?;

        final lat = (polohaData?['lat'] ?? 0.0).toDouble();
        final lon = (polohaData?['lng'] ?? 0.0).toDouble();

        print("Spracovávam '${data['nazov']}': Poloha data: $polohaData, Parsed Lat: $lat, Parsed Lon: $lon");
        
        return Cafe(
          id: doc.id,
          name: data['nazov'] ?? '',
          foto_url: data['foto_url'] ?? '',
          rating: (data['rating'] ?? 0.0).toDouble(),
          isFavorite: data['isFavorite'] ?? false,
          latitude: lat,
          longitude: lon,
        );
      }).toList();
    } catch (e) {
      print('Chyba pri načítaní kaviarní s menu_item $menuItem: $e');
      return [];
    }
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

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(item.id)
          .set(item.toJson());
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
      final QuerySnapshot querySnapshot = await _firestore
          .collection('kaviarne')
          .doc(cafeId)
          .collection('menu_item')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return MenuItem.fromJson(data);
      }).toList();
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
        .collection('menu_item')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return MenuItem.fromJson(data);
          }).toList();
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
} 