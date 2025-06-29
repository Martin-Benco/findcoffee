import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

enum FavoriteType { cafe, drink, food }

class FavoriteItem {
  final FavoriteType type;
  final String id; // pre kaviareň: meno, pre drink/food: meno
  final String name;
  final String? imageUrl;

  FavoriteItem({
    required this.type,
    required this.id,
    required this.name,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'id': id,
    'name': name,
    'imageUrl': imageUrl,
  };

  static FavoriteItem fromJson(Map<String, dynamic> json) => FavoriteItem(
    type: FavoriteType.values.firstWhere((e) => e.name == json['type']),
    id: json['id'],
    name: json['name'],
    imageUrl: json['imageUrl'],
  );
}

class Drink {
  final String name;
  final String imageUrl;
  final bool isFavorite;

  const Drink({required this.name, required this.imageUrl, this.isFavorite = false});
}

class Cafe {
  final String id;
  final String name;
  final String foto_url;
  final double rating;
  double distanceKm;
  final bool isFavorite;
  final double latitude;
  final double longitude;

  Cafe({
    required this.id,
    required this.name,
    required this.foto_url,
    required this.rating,
    this.distanceKm = 0.0,
    this.isFavorite = false,
    required this.latitude,
    required this.longitude,
  });
}

class Food {
  final String name;
  final String imageUrl;

  const Food({required this.name, required this.imageUrl});
}

class MenuItem {
  final String id;
  final String nazov;
  final String cena;
  final String? popis;
  final String? kategoria;
  final String? badge;

  MenuItem({
    required this.id,
    required this.nazov,
    required this.cena,
    this.popis,
    this.kategoria,
    this.badge,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nazov': nazov,
    'cena': cena,
    'popis': popis,
    'kategoria': kategoria,
    'badge': badge,
  };

  static MenuItem fromJson(Map<String, dynamic> json) {
    // Skontrolujeme rôzne možné názvy polí
    final nazov = json['nazov'] ?? json['name'] ?? json['title'] ?? json['produkt'] ?? '';
    final cena = json['cena'] ?? json['price'] ?? json['cost'] ?? '';
    final popis = json['popis'] ?? json['description'] ?? json['desc'];
    final kategoria = json['kategoria'] ?? json['category'] ?? json['type'];
    final badge = json['badge'] ?? json['label'] ?? json['tag'];
    final id = json['id'] ?? json['_id'] ?? nazov; // Použijeme názov ako ID ak ID neexistuje
    
    // Ak je cena číslo, prevedieme ju na string s "eur"
    String cenaString = cena.toString();
    if (cena is num) {
      cenaString = '${cena.toStringAsFixed(2)}€';
    } else if (cena is String && cena.isNotEmpty) {
      // Ak je to string, skontrolujeme či už obsahuje €
      if (!cena.contains('€') && !cena.contains('eur')) {
        cenaString = '$cena€';
      }
    }
    
    return MenuItem(
      id: id,
      nazov: nazov,
      cena: cenaString,
      popis: popis,
      kategoria: kategoria,
      badge: badge,
    );
  }
}

class OpeningHours {
  final String den;
  final String hodiny;
  final bool jeOtvorene;

  OpeningHours({
    required this.den,
    required this.hodiny,
    this.jeOtvorene = true,
  });

  Map<String, dynamic> toJson() => {
    'den': den,
    'hodiny': hodiny,
    'jeOtvorene': jeOtvorene,
  };

  static OpeningHours fromJson(Map<String, dynamic> json) => OpeningHours(
    den: json['den'] ?? '',
    hodiny: json['hodiny'] ?? '',
    jeOtvorene: json['jeOtvorene'] ?? true,
  );
}

List<FavoriteItem> favoritesFromJson(String jsonStr) {
  final list = json.decode(jsonStr) as List<dynamic>;
  return list.map((e) => FavoriteItem.fromJson(e)).toList();
}

String favoritesToJson(List<FavoriteItem> items) {
  return json.encode(items.map((e) => e.toJson()).toList());
}

// Funkcia na získanie aktuálneho používateľa z Firebase Auth
User? getCurrentUser() {
  return FirebaseAuth.instance.currentUser;
}

// Funkcia na získanie emailu aktuálneho používateľa
String? getCurrentUserEmail() {
  return FirebaseAuth.instance.currentUser?.email;
} 