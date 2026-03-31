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
    await prefs.clear();
  }

  /// Comprueba si hay una sesión activa al abrir la app
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> saveUserData(String username, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('email', email);
  }

  Future<Map<String, String>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? '',
    };
  }
  // ==========================================
  // 2. LLAMADAS AL BACKEND (NODE.JS)
  // ==========================================

  /// Iniciar sesión
  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final user = data['user']; // Extraemos el usuario que nos manda Node.js

        if (token != null) {
          await saveToken(token);
          // TFG Info: Guardamos los datos en caché local para usarlos en Ajustes
          if (user != null) {
            await saveUserData(user['username'], user['email']);
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      print("Error de red en login: $e");
      return false;
    }
  }

  /// Registrar un nuevo usuario
  Future<bool> register(String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username, 
          'email': email, 
          'password': password
        }),
      );

      if (response.statusCode == 201) return true;
      print("Registro fallido: ${response.body}");
      return false;
    } catch (e) {
      print("Error de red en registro: $e");
      return false;
    }
  }

  /// Actualizar ajustes de perfil
  Future<bool> updateProfile(String? username, String? email, String? password) async {
    try {
      final token = await getToken();
      
      final Map<String, dynamic> body = {};
      if (username != null && username.isNotEmpty) body['username'] = username;
      if (email != null && email.isNotEmpty) body['email'] = email;
      if (password != null && password.isNotEmpty) body['password'] = password;

      if (body.isEmpty) return true; 

      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/auth/profile'), 
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'];
        // TFG Info: Si se actualiza con éxito, sobrescribimos la caché local con los nuevos datos
        if (user != null) {
          await saveUserData(user['username'], user['email']);
        }
        return true;
      }
      return false;
    } catch (e) {
      print("Error actualizando perfil: $e");
      return false;
    }
  }
}
