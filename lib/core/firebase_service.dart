import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
} 