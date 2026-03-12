import 'dart:convert';
import 'dart:io'; // Necesario para detectar la plataforma
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:http/http.dart' as http;
import '../models/lego_theme.dart';
import '../models/lego_set.dart';
import 'auth_service.dart';

class ApiService {
  // Determinamos la URL base según dónde estemos corriendo
  String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  Future<List<LegoTheme>> getThemes() async {
    // TFG: Añadimos "/lego" a la ruta para que coincida con el app.js del backend
    final response = await http.get(Uri.parse('$_baseUrl/lego/themes'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.map((e) => LegoTheme.fromJson(e)).toList();
    } else {
      // Un chivato útil por si sigue fallando
      debugPrint("Error Backend: ${response.statusCode} - ${response.body}");
      throw Exception('Fallo al cargar temas desde el Backend');
    }
  }

  Future<List<LegoSet>> getSetsByTheme(int themeId) async {
    // TFG: Añadimos "/lego" a la ruta
    final response = await http.get(Uri.parse('$_baseUrl/lego/sets/$themeId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.map((e) => LegoSet.fromJson(e)).toList();
    } else {
      throw Exception('Fallo al cargar sets desde el Backend');
    }
  }

  // Obtener la imagen de portada de un tema (lazy loading)
  Future<String?> getThemeCover(int themeId) async {
    try {
      // TFG: Añadimos "/lego" a la ruta
      final uri = Uri.parse('$_baseUrl/lego/themes/$themeId/cover');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url']; // Puede ser null
      }
    } catch (e) {
      debugPrint('Error fetching theme cover: $e');
    }
    return null;
  }

  String getProxyUrl(String originalUrl) {
    // TFG: Añadimos "/lego" a la ruta
    return '$_baseUrl/lego/image-proxy?url=${Uri.encodeComponent(originalUrl)}';
  }

  // Función para añadir a la colección
  Future<bool> addToCollection(String setNum, double purchasePrice) async {
    final token = await AuthService().getToken();

    if (token == null) throw Exception("Usuario no autenticado");

    // TFG: Esta la dejamos IGUAL, porque app.js dice: app.use('/api/collection', ...)
    final url = Uri.parse('$_baseUrl/collection');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'setNum': setNum,
          'purchasePrice': purchasePrice,
          'quantity': 1, // Por defecto 1
          'condition': 'NISB',
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true; // Se guardó en MongoDB 🎉
      } else {
        print("Error del server: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error de red: $e");
      return false;
    }
  }
}
