import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
  final String name;
  final String foto_url;
  final double rating;
  double distanceKm;
  final bool isFavorite;
  final double latitude;
  final double longitude;

  Cafe({
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

List<FavoriteItem> favoritesFromJson(String jsonStr) {
  final list = json.decode(jsonStr) as List<dynamic>;
  return list.map((e) => FavoriteItem.fromJson(e)).toList();
}

String favoritesToJson(List<FavoriteItem> items) {
  return json.encode(items.map((e) => e.toJson()).toList());
}

String favoritesKeyForUser(String email) => 'favorites_$email';

Future<String?> getCurrentUserEmail() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('email');
} 