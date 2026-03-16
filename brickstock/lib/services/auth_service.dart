import 'dart:convert';
// ¡ELIMINADO dart:io para que funcione en WEB!
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart'; // Importamos el ApiService para usar su URL base

class AuthService {
  // ==========================================
  // 1. GESTIÓN DEL TOKEN (ALMACENAMIENTO LOCAL)
  // ==========================================

  /// Guarda el token en la memoria del dispositivo
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  /// Recupera el token para inyectarlo en las peticiones a Node.js
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  /// Borra el token (Útil para el botón de "Cerrar Sesión")
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  /// Comprueba si hay una sesión activa al abrir la app
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ==========================================
  // 2. LLAMADAS AL BACKEND (NODE.JS)
  // ==========================================

  /// Iniciar sesión
  Future<bool> login(String email, String password) async {
    try {
      // Usamos de forma centralizada ApiService.baseUrl
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];

        if (token != null) {
          await saveToken(token); // Guardamos el token
          return true;
        }
      }
      print("Login fallido (Status ${response.statusCode}): ${response.body}");
      return false;
    } catch (e) {
      print("Error de red en login: $e");
      return false;
    }
  }

  /// Registrar un nuevo usuario
  Future<bool> register(String email, String password) async {
    try {
      // Usamos de forma centralizada ApiService.baseUrl
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 201) {
        return true;
      }
      print(
        "Registro fallido (Status ${response.statusCode}): ${response.body}",
      );
      return false;
    } catch (e) {
      print("Error de red en registro: $e");
      return false;
    }
  }
}
