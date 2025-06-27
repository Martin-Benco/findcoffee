import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream pre sledovanie prihlasovacieho stavu
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Aktuálny používateľ
  User? get currentUser => _auth.currentUser;

  // Registrácia s emailom a heslom (bez mena)
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('=== REGISTRÁCIA POUŽÍVATEĽA ===');
      print('Email: $email');
      print('Heslo dĺžka: ${password.length}');
      
      // Vytvoríme účet v Firebase Auth
      print('Vytváram Firebase Auth účet...');
      UserCredential userCredential;
      
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        print('Používateľ vytvorený s UID: ${userCredential.user?.uid}');
        
      } catch (authError) {
        print('=== CHYBA PRI VYTVÁRANÍ AUTH ÚČTU ===');
        print('Chyba: $authError');
        print('Typ chyby: ${authError.runtimeType}');
        throw authError;
      }

      return userCredential;
    } catch (e) {
      print('=== CHYBA PRI REGISTRÁCII ===');
      print('Chyba: $e');
      print('Typ chyby: ${e.runtimeType}');
      throw _handleAuthError(e);
    }
  }

  // Vytvorenie dokumentu používateľa v Firestore
  Future<void> createUserDocument({
    required String userId,
    required String email,
    required String name,
  }) async {
    try {
      print('=== VYTVÁRANIE DOKUMENTU POUŽÍVATEĽA ===');
      print('User ID: $userId');
      print('Email: $email');
      print('Meno: "$name"');
      
      await _firestore.collection('users').doc(userId).set({
        'email': email,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('Dokument úspešne vytvorený s menom: "$name"');
      
    } catch (e) {
      print('=== CHYBA PRI VYTVÁRANÍ DOKUMENTU ===');
      print('Chyba: $e');
      print('Typ chyby: ${e.runtimeType}');
      throw e;
    }
  }

  // Prihlásenie s emailom a heslom
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Odhlásenie
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Zmena hesla
  Future<void> changePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      }
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Získanie informácií o používateľovi z Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      print('Chyba pri načítaní údajov používateľa: $e');
      return null;
    }
  }

  // Aktualizácia informácií o používateľovi
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      print('Chyba pri aktualizácii údajov používateľa: $e');
      throw e;
    }
  }

  // Získanie mena používateľa priamo z dokumentu
  Future<String?> getUserName(String uid) async {
    try {
      print('=== NAČÍTAVANIE MENA ===');
      print('UID používateľa: $uid');
      
      final doc = await _firestore.collection('users').doc(uid).get();
      print('Dokument existuje: ${doc.exists}');
      
      if (doc.exists) {
        final data = doc.data();
        print('Celý dokument: $data');
        
        // Skontrolujeme všetky polia
        print('Všetky polia v dokumente:');
        data?.forEach((key, value) {
          print('  $key: $value (typ: ${value.runtimeType})');
        });
        
        final name = data?['name'] as String?;
        print('Načítané meno: "$name"');
        print('Typ mena: ${name.runtimeType}');
        
        // Skontrolujeme, či je meno prázdne
        if (name != null) {
          print('Meno nie je null');
          if (name.isEmpty) {
            print('Meno je prázdne string');
            return null;
          } else {
            print('Meno má hodnotu: "$name"');
            return name;
          }
        } else {
          print('Meno je null');
          return null;
        }
      } else {
        print('Dokument neexistuje!');
        return null;
      }
    } catch (e) {
      print('Chyba pri načítaní mena používateľa: $e');
      return null;
    }
  }

  // Aktualizácia mena používateľa priamo v dokumente
  Future<void> updateUserName(String uid, String name) async {
    try {
      print('AuthService: Ukladám meno "$name" pre používateľa: $uid');
      await _firestore.collection('users').doc(uid).update({'name': name});
      print('AuthService: Meno úspešne uložené');
    } catch (e) {
      print('AuthService: Chyba pri aktualizácii mena používateľa: $e');
      throw e;
    }
  }

  // Spracovanie chýb Firebase Auth
  String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'weak-password':
          return 'Heslo je príliš slabé. Použite aspoň 6 znakov.';
        case 'email-already-in-use':
          return 'Tento email je už používaný.';
        case 'user-not-found':
          return 'Používateľ s týmto emailom nebol nájdený.';
        case 'wrong-password':
          return 'Nesprávne heslo.';
        case 'invalid-email':
          return 'Neplatný email.';
        case 'user-disabled':
          return 'Účet bol deaktivovaný.';
        case 'too-many-requests':
          return 'Príliš veľa pokusov. Skúste to neskôr.';
        case 'operation-not-allowed':
          return 'Táto operácia nie je povolená.';
        default:
          return 'Nastala chyba: ${error.message}';
      }
    }
    return 'Nastala neočakávaná chyba.';
  }
} 