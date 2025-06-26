import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream pre sledovanie prihlasovacieho stavu
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Aktuálny používateľ
  User? get currentUser => _auth.currentUser;

  // Registrácia s emailom a heslom
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Vytvoríme účet v Firebase Auth
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Uložíme dodatočné informácie do Firestore
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } catch (e) {
      throw _handleAuthError(e);
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