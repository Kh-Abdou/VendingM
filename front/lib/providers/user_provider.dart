import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  String? _userId;
  String _userName = '';
  String _userEmail = '';
  String _userRole = '';
  double _userBalance = 0.0;
  bool _isLoggedIn = false;

  // Getters
  String get userId => _userId ?? '';
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userRole => _userRole;
  double get userBalance => _userBalance;
  bool get isLoggedIn => _isLoggedIn;

  // Méthode pour définir les infos utilisateur après connexion
  void setUserInfo({
    required String userId,
    required String name,
    required String email,
    required String role,
  }) {
    _userId = userId;
    _userName = name;
    _userEmail = email;
    _userRole = role;
    _isLoggedIn = true;
    notifyListeners();
  }

  // Méthode pour mettre à jour le solde
  void updateBalance(double newBalance) {
    _userBalance = newBalance;
    notifyListeners();
  }

  // Méthode pour déconnecter l'utilisateur
  void logout() {
    _userId = null;
    _userName = '';
    _userEmail = '';
    _userRole = '';
    _userBalance = 0.0;
    _isLoggedIn = false;
    notifyListeners();
  }
}
