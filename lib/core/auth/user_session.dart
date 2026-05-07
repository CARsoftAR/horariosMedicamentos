class UserSession {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  Map<String, dynamic>? _currentUser;

  void login(Map<String, dynamic> user) {
    _currentUser = user;
  }

  void logout() {
    _currentUser = null;
  }

  bool get isLoggedIn => _currentUser != null;
  String get userName => _currentUser?['username'] ?? 'Invitado';
  String get userRole => _currentUser?['role'] ?? 'User';
  int? get userId => _currentUser?['id'];

  bool get isAdmin => userRole == 'Admin';
}
