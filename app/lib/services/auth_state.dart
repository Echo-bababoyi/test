class AuthState {
  static final AuthState instance = AuthState._();
  AuthState._();

  bool isLoggedIn = false;
  String? userName;

  void login({String? name}) {
    isLoggedIn = true;
    userName = name;
  }

  void logout() {
    isLoggedIn = false;
    userName = null;
  }
}
