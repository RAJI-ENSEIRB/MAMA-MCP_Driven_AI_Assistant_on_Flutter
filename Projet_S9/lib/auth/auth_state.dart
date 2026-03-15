import 'package:flutter/foundation.dart';
import 'google_auth_service.dart';

class AuthState extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _hasChosen = false;

  bool get isLoggedIn => _isLoggedIn;
  bool get hasChosen => _hasChosen;

  AuthState() {
    _init();
  }

  Future<void> _init() async {
    final user = await GoogleAuthService.signInSilently();
    if (user != null) {
      _isLoggedIn = true;
      _hasChosen = true;
      notifyListeners();
    }
  }

  Future<void> login() async {
    final account = await GoogleAuthService.signIn();
    if (account != null) {
      _isLoggedIn = true;
      _hasChosen = true;
      notifyListeners();
    }
  }

  void skipLogin() {
    _isLoggedIn = false;
    _hasChosen = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await GoogleAuthService.signOut();
    _isLoggedIn = false;
    _hasChosen = false;
    notifyListeners();
  }
}
