import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class UserProvider extends ChangeNotifier {
  String _username = "Perfil";
  String _avatar = "assets/avatars/lego-default.jpg";
  final AuthService _authService = AuthService();

  String get username => _username;
  String get avatar => _avatar;

  // Carga inicial
  Future<void> loadUserData() async {
    final data = await _authService.getUserData();
    _username = data['username'] ?? "Perfil";
    _avatar = data['avatar'] ?? "assets/avatars/lego-default.jpg";
    notifyListeners(); // Avisa a la app para que se dibuje de nuevo
  }

  // Método para actualizar solo el avatar al instante
  void updateAvatar(String newPath) {
    _avatar = newPath;
    notifyListeners(); // Actualiza al instante Navbar e Inicio
  }

  //Metodo para eliminar los datos de la cache del dispositivo
  void clearUserData() {
    _username = "Perfil";
    _avatar = "assets/avatars/lego-default.jpg";
    notifyListeners(); // Avisa a la app para que quite los datos de la pantalla
  }
}