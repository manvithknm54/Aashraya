import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── REGISTER ──
  Future<String?> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    try {
      // Check if email already exists in Firestore with ANY role
      final existing = await _db
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        final existingRole = existing.docs.first.data()['role'];
        if (existingRole == role) {
          return 'This email is already registered as $role.';
        } else {
          // Email exists but with a DIFFERENT role
          return 'This email is already registered as a '
              '${existingRole == "elder" ? "Elder" : "Caretaker"}. '
              'Please use a different email.';
        }
      }

      // Safe to register
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;
      await credential.user!.updateDisplayName(name.trim());

      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'linkedTo': null,
      });

      return null; // success
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e.code);
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  // ── LOGIN — with ROLE VERIFICATION ──
  Future<String?> login({
    required String email,
    required String password,
    required String expectedRole,
  }) async {
    try {
      // Sign in first
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;

      // Fetch role from Firestore
      final doc = await _db.collection('users').doc(uid).get();

      if (!doc.exists) {
        // Account exists in Auth but not Firestore — sign out
        await _auth.signOut();
        return 'Account data not found. Please register again.';
      }

      final actualRole = doc.data()?['role'] as String?;

      // ── ROLE MISMATCH CHECK ──
      if (actualRole != expectedRole) {
        await _auth.signOut();
        if (actualRole == 'elder') {
          return 'This account is registered as an Elder.\n'
              'Please go back and select "I am an Elder" to sign in.';
        } else {
          return 'This account is registered as a Caretaker.\n'
              'Please go back and select "I am a Caretaker" to sign in.';
        }
      }

      return null; // success — role matches
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e.code);
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  // ── GET USER ROLE ──
  Future<String?> getUserRole() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data()?['role'] as String?;
    } catch (e) {
      return null;
    }
  }

  // ── GET USER DATA ──
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  // ── LOGOUT ──
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ── Error handler ──
  String _handleAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  // ── Check if elder is linked to a caretaker ──
  Future<bool> isLinkedToCaretaker() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return false;
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return false;
      final data = doc.data();
      if (data == null) return false;

      // Only elders need linking check
      if (data['role'] != 'elder') return true;

      final linkedTo = data['linkedTo'];
      return linkedTo != null && linkedTo.toString().trim().isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ── Search caretakers by name, email, or phone ──
  Future<List<Map<String, dynamic>>> searchCaretakers(String query) async {
    try {
      query = query.trim().toLowerCase();
      if (query.isEmpty) return [];

      // Get all caretakers then filter client-side
      // Firestore doesn't support OR queries across fields.
      final snap = await _db
          .collection('users')
          .where('role', isEqualTo: 'caretaker')
          .get();

      final results = snap.docs
          .map((d) => {'uid': d.id, ...d.data()})
          .where((c) {
        final name = (c['name'] as String? ?? '').toLowerCase();
        final email = (c['email'] as String? ?? '').toLowerCase();
        final phone = (c['phone'] as String? ?? '').toLowerCase();

        return name.contains(query) ||
            email.contains(query) ||
            phone.contains(query);
      }).toList();

      return results;
    } catch (e) {
      return [];
    }
  }

  // ── Link elder to caretaker ──
  Future<String?> linkToCaretaker({
    required String elderUid,
    required String caretakerUid,
  }) async {
    try {
      final batch = _db.batch();

      // Elder doc → linkedTo caretaker
      batch.update(
        _db.collection('users').doc(elderUid),
        {'linkedTo': caretakerUid},
      );

      // Caretaker doc → add elder to linkedElders array
      batch.update(
        _db.collection('users').doc(caretakerUid),
        {
          'linkedElders': FieldValue.arrayUnion([elderUid]),
        },
      );

      await batch.commit();
      return null; // success
    } catch (e) {
      return 'Failed to link. Please try again.';
    }
  }

  // ── Unlink elder from current caretaker ──
  Future<String?> unlinkCaretaker({
    required String elderUid,
    required String caretakerUid,
  }) async {
    try {
      final batch = _db.batch();

      batch.update(
        _db.collection('users').doc(elderUid),
        {'linkedTo': null},
      );

      batch.update(
        _db.collection('users').doc(caretakerUid),
        {
          'linkedElders': FieldValue.arrayRemove([elderUid]),
        },
      );

      await batch.commit();
      return null;
    } catch (e) {
      return 'Failed to unlink. Please try again.';
    }
  }
}
