import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  //  apuntamos a la ruta de auth
  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:3000/api/auth';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000/api/auth';
    return 'http://localhost:3000/api/auth'; // iOS
  }

  // Función para INICIAR SESIÓN
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        // Empaquetamos el email y contraseña en formato JSON
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      // Si el backend nos devuelve un 200 OK (Login exitoso)
      if (response.statusCode == 200) {
        // 1. Abrimos la memoria del móvil
        final prefs = await SharedPreferences.getInstance();

        // 2. Guardamos el Token (Pase VIP) con el nombre 'jwt_token'
        await prefs.setString('jwt_token', data['token']);

        return {'success': true, 'message': 'Bienvenido'};
      } else {
        // Si hay error (ej: contraseña incorrecta), leemos el mensaje de tu backend
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión con el servidor'};
    }
  }

  // Función para CERRAR SESIÓN (Borrar el pase VIP)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }
}
