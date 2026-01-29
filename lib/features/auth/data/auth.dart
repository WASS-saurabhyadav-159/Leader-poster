import 'package:shared_preferences/shared_preferences.dart';

class Auth {
  SharedPreferences _pref;
  
  Auth(this._pref);
 
  AuthState getAuthState() {
    if (_pref.getString("status") == AuthState.loggedIn.name) {
      return AuthState.loggedIn;
    }
    return AuthState.loggedOut;
  }
  
  Future<void> forgotPassword() async {}
}

enum AuthState {
  loggedIn,
  loggedOut
}