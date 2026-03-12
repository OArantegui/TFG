import 'dart:convert';
import 'dart:io' show Platform; // Importación segura
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // ==========================================
  // CONFIGURACIÓN DE LA URL BASE (MULTIPLATAFORMA)
  // ==========================================
  String get _baseUrl {
    // 1. Si estamos ejecutando en Chrome/Edge (Web)
    if (kIsWeb) {
      return 'http://localhost:3000/api/auth';
    }
    // 2. Si estamos en el Emulador de Android
    // (10.0.2.2 es el alias mágico del emulador para acceder al localhost de tu PC)
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api/auth';
    }
    // 3. Si estamos en el Simulador de iOS, Windows, Linux o Mac
    return 'http://localhost:3000/api/auth';
  }

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
      // TFG: Corrección de inyección de variable ($_baseUrl)
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
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
      // TFG: Corrección de inyección de variable ($_baseUrl)
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      // 201 Created es el código estándar REST para creaciones exitosas
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
