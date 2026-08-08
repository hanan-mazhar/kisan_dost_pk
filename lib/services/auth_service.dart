import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();


  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String role,
    required String city,
    String? walletNumber,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = cred.user!.uid;

    // Step 2: Update display name
    await cred.user!.updateDisplayName(fullName.trim());

    // Step 3: Build user model
    final user = UserModel(
      id: uid,
      fullName: fullName.trim(),
      phoneNumber: phoneNumber.trim(),
      email: email.trim(),
      role: role,
      city: city,
      walletNumber:
          (walletNumber?.trim().isNotEmpty == true) ? walletNumber!.trim() : null,
      rating: 0.0,
      totalRatings: 0,
      createdAt: DateTime.now(),
    );

    // Step 4: Save to Firestore (with retry on network error)
    try {
      await _db
          .collection(AppConstants.usersCol)
          .doc(uid)
          .set(user.toMap());
    } catch (firestoreError) {
      
    }

    await _savePrefs(uid, role);

    return user;
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = cred.user!.uid;

    UserModel? user;
    try {
      final doc = await _db
          .collection(AppConstants.usersCol)
          .doc(uid)
          .get(const GetOptions(source: Source.serverAndCache));

      if (doc.exists && doc.data() != null) {
        user = UserModel.fromMap(doc.data()!, doc.id);
      }
    } catch (_) {
      try {
        final doc = await _db
            .collection(AppConstants.usersCol)
            .doc(uid)
            .get(const GetOptions(source: Source.cache));
        if (doc.exists && doc.data() != null) {
          user = UserModel.fromMap(doc.data()!, doc.id);
        }
      } catch (_) {}
    }

    if (user == null) {
      final prefs = await SharedPreferences.getInstance();
      final savedRole = prefs.getString(AppConstants.prefUserRole) ?? AppConstants.roleFarmer;
      user = UserModel(
        id: uid,
        fullName: cred.user!.displayName ?? email.split('@').first,
        phoneNumber: cred.user!.phoneNumber ?? '',
        email: email.trim(),
        role: savedRole,
        city: 'Lahore',
        createdAt: DateTime.now(),
      );
    }

    await _savePrefs(uid, user.role);
    return user;
  }

  Future<UserModel?> getCurrentUser() async {
    final u = _auth.currentUser;
    if (u == null) return null;

    try {
      final doc = await _db
          .collection(AppConstants.usersCol)
          .doc(u.uid)
          .get(const GetOptions(source: Source.serverAndCache));
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
    } catch (_) {
      try {
        final doc = await _db
            .collection(AppConstants.usersCol)
            .doc(u.uid)
            .get(const GetOptions(source: Source.cache));
        if (doc.exists && doc.data() != null) {
          return UserModel.fromMap(doc.data()!, doc.id);
        }
      } catch (_) {}
    }

    // Fall back to auth user
    final prefs = await SharedPreferences.getInstance();
    final savedRole =
        prefs.getString(AppConstants.prefUserRole) ?? AppConstants.roleFarmer;
    return UserModel(
      id: u.uid,
      fullName: u.displayName ?? u.email?.split('@').first ?? 'User',
      phoneNumber: u.phoneNumber ?? '',
      email: u.email ?? '',
      role: savedRole,
      city: 'Lahore',
      createdAt: DateTime.now(),
    );
  }

  Future<void> updateUser(UserModel user) async {
    await _db
        .collection(AppConstants.usersCol)
        .doc(user.id)
        .set(user.toMap(), SetOptions(merge: true));
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> _savePrefs(String uid, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefUserId, uid);
    await prefs.setString(AppConstants.prefUserRole, role);
  }

  Future<String?> getSavedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefUserRole);
  }
}
