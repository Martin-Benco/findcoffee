import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static const String _userNameKey = 'user_name';
  static const String _userIdKey = 'user_id';

  // Uloženie mena lokálne
  static Future<void> saveUserName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userNameKey, name);
      print('SharedPreferences: Meno uložené lokálne: "$name"');
    } catch (e) {
      print('SharedPreferences: Chyba pri ukladaní mena: $e');
      throw e;
    }
  }

  // Načítanie mena lokálne
  static Future<String?> getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_userNameKey);
      print('SharedPreferences: Načítané lokálne meno: "$name"');
      return name;
    } catch (e) {
      print('SharedPreferences: Chyba pri načítaní mena: $e');
      return null;
    }
  }

  // Uloženie user ID
  static Future<void> saveUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, userId);
      print('SharedPreferences: User ID uložené: $userId');
    } catch (e) {
      print('SharedPreferences: Chyba pri ukladaní user ID: $e');
      throw e;
    }
  }

  // Načítanie user ID
  static Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_userIdKey);
      print('SharedPreferences: Načítané user ID: $userId');
      return userId;
    } catch (e) {
      print('SharedPreferences: Chyba pri načítaní user ID: $e');
      return null;
    }
  }

  // Vymazanie všetkých údajov
  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('SharedPreferences: Všetky údaje vymazané');
    } catch (e) {
      print('SharedPreferences: Chyba pri mazaní údajov: $e');
      throw e;
    }
  }

  // Kontrola, či máme uložené meno
  static Future<bool> hasUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasName = prefs.containsKey(_userNameKey);
      print('SharedPreferences: Má uložené meno: $hasName');
      return hasName;
    } catch (e) {
      print('SharedPreferences: Chyba pri kontrole mena: $e');
      return false;
    }
  }
} 