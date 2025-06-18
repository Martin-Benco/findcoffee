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