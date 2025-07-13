/// Utility funkcie pre aplikáciu
class AppUtils {
  /// Formátuje vzdialenosť podľa pravidiel:
  /// - Ak je menej ako 1 km: zobrazí v metroch (napr. "850 m")
  /// - Ak je 1-2 km: zobrazí s jedným desatinným miestom (napr. "1.2 km")
  /// - Ak je viac ako 2 km: zobrazí v kilometroch ako celé čísla (napr. "3 km")
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1.0) {
      // Menej ako 1 km - zobrazíme v metroch
      final meters = (distanceKm * 1000).round();
      return '$meters m';
    } else if (distanceKm <= 2.0) {
      // 1-2 km - zobrazíme s jedným desatinným miestom
      return '${distanceKm.toStringAsFixed(1)} km';
    } else {
      // Viac ako 2 km - zobrazíme v kilometroch ako celé čísla
      final kilometers = distanceKm.round();
      return '$kilometers km';
    }
  }
} 