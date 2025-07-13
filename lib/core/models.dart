import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

enum FavoriteType { cafe, drink, food }

class FavoriteItem {
  final FavoriteType type;
  final String id; // pre kaviareň: meno, pre drink/food: meno
  final String name;
  final String? imageUrl;
  final String? note;
  final String? address; // adresa kaviarne
  final DateTime? savedAt; // dátum uloženia

  FavoriteItem({
    required this.type,
    required this.id,
    required this.name,
    this.imageUrl,
    this.note,
    this.address,
    this.savedAt,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'id': id,
    'name': name,
    'imageUrl': imageUrl,
    'note': note,
    'address': address,
    'savedAt': savedAt?.toIso8601String(),
  };

  static FavoriteItem fromJson(Map<String, dynamic> json) => FavoriteItem(
    type: FavoriteType.values.firstWhere((e) => e.name == json['type']),
    id: json['id'],
    name: json['name'],
    imageUrl: json['imageUrl'],
    note: json['note'],
    address: json['address'],
    savedAt: json['savedAt'] != null ? DateTime.parse(json['savedAt']) : null,
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
  final String? address; // adresa kaviarne

  Cafe({
    required this.id,
    required this.name,
    required this.foto_url,
    required this.rating,
    this.distanceKm = 0.0,
    this.isFavorite = false,
    required this.latitude,
    required this.longitude,
    this.address,
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

  /// Určí, či je kaviareň aktuálne otvorená
  bool isCurrentlyOpen() {
    if (!jeOtvorene || hodiny.isEmpty || hodiny.toLowerCase() == 'zatvorené') {
      return false;
    }

    final now = DateTime.now();
    final currentDay = now.weekday; // 1 = Monday, 7 = Sunday
    
    // Mapovanie dní týždňa
    final dayMapping = {
      'Po': 1, 'Ut': 2, 'St': 3, 'Št': 4, 'Pi': 5, 'So': 6, 'Ne': 7,
      'Pondelok': 1, 'Utorok': 2, 'Streda': 3, 'Štvrtok': 4, 'Piatok': 5, 'Sobota': 6, 'Nedeľa': 7,
      'Monday': 1, 'Tuesday': 2, 'Wednesday': 3, 'Thursday': 4, 'Friday': 5, 'Saturday': 6, 'Sunday': 7,
    };

    // Skontrolujeme, či je dnešný deň
    if (!dayMapping.containsKey(den)) {
      return false;
    }

    if (dayMapping[den] != currentDay) {
      return false;
    }

    // Parsujeme hodiny
    try {
      final timeRange = hodiny.replaceAll(' ', '').replaceAll('–', '-').replaceAll('—', '-');
      final parts = timeRange.split('-');
      
      if (parts.length != 2) {
        return false;
      }

      final openTime = _parseTime(parts[0]);
      final closeTime = _parseTime(parts[1]);
      
      if (openTime == null || closeTime == null) {
        return false;
      }

      final currentTime = now.hour * 60 + now.minute;
      
      // Ak je zatvárací čas menší ako otvárací, znamená to, že kaviareň je otvorená cez noc
      if (closeTime < openTime) {
        return currentTime >= openTime || currentTime <= closeTime;
      } else {
        return currentTime >= openTime && currentTime <= closeTime;
      }
    } catch (e) {
      return false;
    }
  }

  /// Parsuje čas z formátu "HH:MM" alebo "HH.MM" alebo "HH:MM AM/PM" (štandardne: 12 AM = 00:00, 12 PM = 12:00)
  int? _parseTime(String timeStr) {
    try {
      timeStr = timeStr.trim();
      // Odstránime prípadné "h" alebo "hod"
      timeStr = timeStr.replaceAll(RegExp(r'[hH]'), '').replaceAll('hod', '').trim();
      // Skontrolujeme AM/PM
      bool isPM = false;
      bool isAM = false;
      if (timeStr.toLowerCase().contains('pm')) {
        isPM = true;
        timeStr = timeStr.toLowerCase().replaceAll('pm', '').trim();
      } else if (timeStr.toLowerCase().contains('am')) {
        isAM = true;
        timeStr = timeStr.toLowerCase().replaceAll('am', '').trim();
      }
      int hours = 0;
      int minutes = 0;
      if (timeStr.contains(':')) {
        final parts = timeStr.split(':');
        hours = int.parse(parts[0]);
        minutes = int.parse(parts[1]);
      } else if (timeStr.contains('.')) {
        final parts = timeStr.split('.');
        hours = int.parse(parts[0]);
        minutes = int.parse(parts[1]);
      } else {
        hours = int.parse(timeStr);
        minutes = 0;
      }
      // Štandardná logika: 12 AM = 00:00, 12 PM = 12:00
      if (isAM && hours == 12) {
        hours = 0;
      } else if (isPM && hours != 12) {
        hours += 12;
      }
      if (hours >= 24) hours -= 24;
      return hours * 60 + minutes;
    } catch (e) {
      return null;
    }
  }

  /// Vráti formátovaný čas pre zobrazenie v 24h formáte
  String getFormattedHours() {
    if (hodiny.isEmpty || hodiny.toLowerCase() == 'zatvorené') {
      return 'Zatvorené';
    }
    // Rozdelíme na od–do
    final timeRange = hodiny.replaceAll(' ', '').replaceAll('–', '-').replaceAll('—', '-');
    final parts = timeRange.split('-');
    if (parts.length != 2) return hodiny;
    final from = _formatTo24h(parts[0]);
    final to = _formatTo24h(parts[1]);
    return '$from – $to';
  }

  /// Pomocná funkcia na prevod času do 24h formátu
  String _formatTo24h(String timeStr) {
    timeStr = timeStr.trim();
    bool isPM = false;
    bool isAM = false;
    if (timeStr.toLowerCase().contains('pm')) {
      isPM = true;
      timeStr = timeStr.toLowerCase().replaceAll('pm', '').trim();
    } else if (timeStr.toLowerCase().contains('am')) {
      isAM = true;
      timeStr = timeStr.toLowerCase().replaceAll('am', '').trim();
    }
    int hours = 0;
    int minutes = 0;
    if (timeStr.contains(':')) {
      final parts = timeStr.split(':');
      hours = int.parse(parts[0]);
      minutes = int.parse(parts[1]);
    } else if (timeStr.contains('.')) {
      final parts = timeStr.split('.');
      hours = int.parse(parts[0]);
      minutes = int.parse(parts[1]);
    } else {
      hours = int.parse(timeStr);
      minutes = 0;
    }
    // Podľa požiadavky: 12:00 AM = 12:00 (obed), 12:00 PM = 00:00 (polnoc)
    if (isAM && hours == 12) {
      hours = 12;
    } else if (isPM && hours == 12) {
      hours = 0;
    } else if (isPM && hours != 12) {
      hours += 12;
    }
    if (hours >= 24) hours -= 24;
    final h = hours.toString().padLeft(2, '0');
    final m = minutes.toString().padLeft(2, '0');
    return '$h:$m';
  }
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