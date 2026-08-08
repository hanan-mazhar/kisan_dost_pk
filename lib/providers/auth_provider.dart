import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final NotificationService _notifSvc = NotificationService();

  UserModel? _currentUser;
  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;

  // Global notification listener — active as long as user is logged in
  StreamSubscription? _notifSubscription;

  UserModel? get currentUser => _currentUser;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  // ── INIT ──────────────────────────────────────────────────────────────────
  Future<void> init() async {
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      _currentUser = await _authService.getCurrentUser();
      _status = _currentUser != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;

      // Start global listener if already logged in
      if (_currentUser != null) {
        _startNotificationListener(_currentUser!.id);
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // ── SIGN UP ───────────────────────────────────────────────────────────────
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String role,
    required String city,
    String? walletNumber,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _currentUser = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
        role: role,
        city: city,
        walletNumber: walletNumber,
      );
      _status = AuthStatus.authenticated;
      _startNotificationListener(_currentUser!.id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseError(e.toString());
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ── LOGIN ─────────────────────────────────────────────────────────────────
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _currentUser = await _authService.login(
        email: email,
        password: password,
      );
      _status = AuthStatus.authenticated;
      _startNotificationListener(_currentUser!.id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseError(e.toString());
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ── SIGN OUT ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    _stopNotificationListener();
    await _authService.signOut();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ── UPDATE USER ───────────────────────────────────────────────────────────
  Future<void> updateUser(UserModel user) async {
    await _authService.updateUser(user);
    _currentUser = user;
    notifyListeners();
  }

  // ── CLEAR ERROR ───────────────────────────────────────────────────────────
  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // ── GLOBAL NOTIFICATION LISTENER ─────────────────────────────────────────
  /// Starts listening to Firestore notifications at the app level.
  /// This means banners show regardless of which screen is open.
  void _startNotificationListener(String userId) {
    _stopNotificationListener(); // cancel any previous listener first

    _notifSubscription =
        _notifSvc.listenToNotifications(userId, showBanners: true).listen((_) {
      // The stream handler inside NotificationService already calls
      // _showLocalNotification() for every new doc — nothing extra needed here.
      // We just keep the subscription alive so the stream stays active.
    });
  }

  void _stopNotificationListener() {
    _notifSubscription?.cancel();
    _notifSubscription = null;
  }

  @override
  void dispose() {
    _stopNotificationListener();
    super.dispose();
  }

  // ── ERROR PARSER ──────────────────────────────────────────────────────────
  String _parseError(String error) {
    if (error.contains('email-already-in-use')) {
      return 'This email is already registered.';
    } else if (error.contains('wrong-password')) {
      return 'Incorrect password. Please try again.';
    } else if (error.contains('user-not-found')) {
      return 'No account found with this email.';
    } else if (error.contains('weak-password')) {
      return 'Password is too weak. Use at least 6 characters.';
    } else if (error.contains('network-request-failed')) {
      return 'Network error. Please check your connection.';
    }
    return 'An error occurred. Please try again.';
  }
}
