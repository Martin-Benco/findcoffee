import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'shared_preferences_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream pre sledovanie prihlasovacieho stavu
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Aktuálny používateľ
  User? get currentUser => _auth.currentUser;

  // Registrácia s emailom, heslom a menom
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      print('=== REGISTRÁCIA POUŽÍVATEĽA ===');
      print('Email: $email');
      print('Heslo dĺžka: ${password.length}');
      print('Meno: "$name"');
      
      // Najprv uložíme meno lokálne
      await SharedPreferencesService.saveUserName(name);
      print('Meno uložené lokálne: "$name"');
      
      // Vytvoríme účet v Firebase Auth
      print('Vytváram Firebase Auth účet...');
      UserCredential userCredential;
      
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        print('Používateľ vytvorený s UID: ${userCredential.user?.uid}');
        
        // Uložíme user ID lokálne
        await SharedPreferencesService.saveUserId(userCredential.user!.uid);
        print('User ID uložené lokálne: ${userCredential.user!.uid}');
        
        // IHNEĎ vytvoríme dokument v Firestore s menom
        print('Vytváram dokument používateľa v Firestore...');
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'name': name,
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('Dokument používateľa úspešne vytvorený v Firestore s menom: "$name"');
        
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

  // Vytvorenie dokumentu používateľa v Firestore (zachované pre kompatibilitu)
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
      print('=== PRIHLÁSENIE POUŽÍVATEĽA ===');
      print('Email: $email');
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('Používateľ prihlásený s UID: ${userCredential.user?.uid}');
      
      // Uložíme user ID lokálne
      await SharedPreferencesService.saveUserId(userCredential.user!.uid);
      print('User ID uložené lokálne: ${userCredential.user!.uid}');
      
      // Načítame meno z Firestore a uložíme lokálne
      final name = await getUserName(userCredential.user!.uid);
      if (name != null) {
        await SharedPreferencesService.saveUserName(name);
        print('Meno načítané z Firestore a uložené lokálne: "$name"');
      } else {
        print('Meno sa nenašlo v Firestore');
      }
      
      return userCredential;
    } catch (e) {
      print('=== CHYBA PRI PRIHLÁSENÍ ===');
      print('Chyba: $e');
      throw _handleAuthError(e);
    }
  }

  // Odhlásenie
  Future<void> signOut() async {
    try {
      print('=== ODHLÁSENIE POUŽÍVATEĽA ===');
      await _auth.signOut();
      // Vymažeme lokálne údaje
      await SharedPreferencesService.clearAllData();
      print('Používateľ odhlásený a lokálne údaje vymazané');
    } catch (e) {
      print('Chyba pri odhlásení: $e');
      throw e;
    }
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

  // Získanie mena používateľa z Firestore
  Future<String?> getUserName(String uid) async {
    try {
      print('=== NAČÍTAVANIE MENA Z FIRESTORE ===');
      print('UID používateľa: $uid');
      
      final doc = await _firestore.collection('users').doc(uid).get();
      print('Dokument existuje: ${doc.exists}');
      
      if (doc.exists) {
        final data = doc.data();
        print('Celý dokument: $data');
        
        final name = data?['name'] as String?;
        print('Načítané meno z Firestore: "$name"');
        
        if (name != null && name.isNotEmpty) {
          print('Meno má hodnotu: "$name"');
          return name;
        } else {
          print('Meno je prázdne alebo null');
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

  // Aktualizácia mena používateľa - najprv lokálne, potom Firestore
  Future<void> updateUserName(String uid, String name) async {
    try {
      print('=== AKTUALIZÁCIA MENA ===');
      print('UID: $uid');
      print('Nové meno: "$name"');
      
      // Najprv aktualizujeme lokálne
      await SharedPreferencesService.saveUserName(name);
      print('Meno aktualizované lokálne');
      
      // Skontrolujeme, či dokument používateľa existuje
      final doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        // Dokument existuje - aktualizujeme ho
        await _firestore.collection('users').doc(uid).update({'name': name});
        print('Meno aktualizované v existujúcom dokumente Firestore');
      } else {
        // Dokument neexistuje - vytvoríme ho
        print('Dokument používateľa neexistuje, vytváram nový...');
        final user = _auth.currentUser;
        if (user != null) {
          await _firestore.collection('users').doc(uid).set({
            'email': user.email,
            'name': name,
            'createdAt': FieldValue.serverTimestamp(),
          });
          print('Nový dokument používateľa vytvorený s menom: "$name"');
        } else {
          throw Exception('Používateľ nie je prihlásený');
        }
      }
      
    } catch (e) {
      print('Chyba pri aktualizácii mena používateľa: $e');
      throw e;
    }
  }

  // Získanie mena lokálne
  Future<String?> getLocalUserName() async {
    return await SharedPreferencesService.getUserName();
  }

  // Získanie user ID lokálne
  Future<String?> getLocalUserId() async {
    return await SharedPreferencesService.getUserId();
  }

  // Re-autentifikácia a vymazanie účtu
  Future<void> reAuthenticateAndDeleteAccount(String password) async {
    try {
      print('=== RE-AUTENTIFIKÁCIA A VYMAZANIE ÚČTU ===');
      final user = _auth.currentUser;
      
      if (user == null) {
        throw Exception('Používateľ nie je prihlásený');
      }
      
      final uid = user.uid;
      final email = user.email;
      
      if (email == null) {
        throw Exception('Email používateľa nie je dostupný');
      }
      
      print('Re-autentifikujem používateľa s UID: $uid');
      print('Email: $email');
      
      // Najprv skúsime vymazať účet priamo bez re-autentifikácie
      try {
        print('Skúšam vymazať účet priamo bez re-autentifikácie...');
        await deleteAccount();
        print('Účet úspešne vymazaný bez re-autentifikácie');
        return;
      } catch (directDeleteError) {
        if (directDeleteError.toString().contains('requires-recent-login') ||
            directDeleteError.toString().contains('znovu zadať heslo')) {
          print('Vyžaduje sa re-autentifikácia, pokračujem...');
        } else {
          // Ak je iná chyba, pokračujeme s re-autentifikáciou
          print('Iná chyba pri priamom vymazaní: $directDeleteError');
        }
      }
      
      // Re-autentifikujeme používateľa
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      
      print('Vytváram credential pre re-autentifikáciu...');
      await user.reauthenticateWithCredential(credential);
      print('Používateľ úspešne re-autentifikovaný');
      
      // Teraz môžeme vymazať účet
      print('Začínam vymazávanie účtu...');
      await deleteAccount();
      
    } catch (e) {
      print('=== CHYBA PRI RE-AUTENTIFIKÁCII ===');
      print('Chyba: $e');
      print('Typ chyby: ${e.runtimeType}');
      
      if (e is FirebaseAuthException) {
        print('Firebase Auth chyba - kód: ${e.code}');
        print('Firebase Auth chyba - správa: ${e.message}');
        throw _handleAuthError(e);
      }
      
      throw Exception('Chyba pri re-autentifikácii: $e');
    }
  }

  // Alternatívna re-autentifikácia a vymazanie účtu
  Future<void> alternativeReAuthenticateAndDeleteAccount(String password) async {
    try {
      print('=== ALTERNATÍVNA RE-AUTENTIFIKÁCIA A VYMAZANIE ÚČTU ===');
      final user = _auth.currentUser;
      
      if (user == null) {
        throw Exception('Používateľ nie je prihlásený');
      }
      
      final uid = user.uid;
      final email = user.email;
      
      if (email == null) {
        throw Exception('Email používateľa nie je dostupný');
      }
      
      print('Alternatívna re-autentifikácia používateľa s UID: $uid');
      print('Email: $email');
      
      // Odhlásime používateľa
      await _auth.signOut();
      print('Používateľ odhlásený pre re-autentifikáciu');
      
      // Prihlásime ho znova s heslami
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Používateľ úspešne re-autentifikovaný alternatívnou metódou');
      
      // Teraz môžeme vymazať účet
      print('Začínam vymazávanie účtu...');
      await deleteAccount();
      
    } catch (e) {
      print('=== CHYBA PRI ALTERNATÍVNEJ RE-AUTENTIFIKÁCII ===');
      print('Chyba: $e');
      print('Typ chyby: ${e.runtimeType}');
      
      if (e is FirebaseAuthException) {
        print('Firebase Auth chyba - kód: ${e.code}');
        print('Firebase Auth chyba - správa: ${e.message}');
        throw _handleAuthError(e);
      }
      
      throw Exception('Chyba pri alternatívnej re-autentifikácii: $e');
    }
  }

  // Vymazanie účtu - vymaže všetky údaje z Firebase
  Future<void> deleteAccount() async {
    try {
      print('=== VYMAZANIE ÚČTU ===');
      final user = _auth.currentUser;
      
      if (user == null) {
        throw Exception('Používateľ nie je prihlásený');
      }
      
      final uid = user.uid;
      print('Vymazávam účet pre UID: $uid');
      
      // 1. Najprv vymažeme všetky obľúbené položky používateľa
      print('Vymazávam obľúbené položky...');
      try {
        final favoritesQuery = await _firestore
            .collection('users')
            .doc(uid)
            .collection('favorites')
            .get();
        
        if (favoritesQuery.docs.isNotEmpty) {
          final batch = _firestore.batch();
          for (var doc in favoritesQuery.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
          print('Obľúbené položky vymazané');
        } else {
          print('Žiadne obľúbené položky na vymazanie');
        }
      } catch (e) {
        print('Chyba pri vymazávaní obľúbených položiek: $e');
        // Pokračujeme aj keď sa obľúbené položky nevymazali
      }
      
      // 2. Vymažeme dokument používateľa z kolekcie 'users'
      print('Vymazávam dokument používateľa...');
      try {
        await _firestore.collection('users').doc(uid).delete();
        print('Dokument používateľa vymazaný');
      } catch (e) {
        print('Chyba pri vymazávaní dokumentu používateľa: $e');
        // Pokračujeme aj keď sa dokument nevymazal
      }
      
      // 3. Vymažeme lokálne údaje
      print('Vymazávam lokálne údaje...');
      try {
        await SharedPreferencesService.clearAllData();
        print('Lokálne údaje vymazané');
      } catch (e) {
        print('Chyba pri vymazávaní lokálnych údajov: $e');
      }
      
      // 4. Nakoniec vymažeme Firebase Auth účet
      print('Vymazávam Firebase Auth účet...');
      try {
        await user.delete();
        print('Firebase Auth účet vymazaný');
      } catch (authError) {
        if (authError is FirebaseAuthException && 
            authError.code == 'requires-recent-login') {
          print('Vyžaduje sa re-autentifikácia pred vymazaním účtu');
          throw Exception('Pre vymazanie účtu je potrebné znovu zadať heslo');
        } else {
          print('Chyba pri vymazávaní Auth účtu: $authError');
          rethrow;
        }
      }
      
      print('=== ÚČET ÚSPEŠNE VYMAZANÝ ===');
      
    } catch (e) {
      print('=== CHYBA PRI VYMAZÁVANÍ ÚČTU ===');
      print('Chyba: $e');
      print('Typ chyby: ${e.runtimeType}');
      
      // Ak je chyba súvisiaca s Firebase Auth, spracujeme ju
      if (e is FirebaseAuthException) {
        throw _handleAuthError(e);
      }
      
      throw Exception('Chyba pri vymazávaní účtu: $e');
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