class Drink {
  final String name;
  final String imageUrl;
  final bool isFavorite;

  const Drink({required this.name, required this.imageUrl, this.isFavorite = false});
}

class Cafe {
  final String name;
  final String imageUrl;
  final double rating;
  final double distanceKm;
  final bool isFavorite;

  const Cafe({
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.distanceKm,
    this.isFavorite = false,
  });
}

class Food {
  final String name;
  final String imageUrl;

  const Food({required this.name, required this.imageUrl});
} 