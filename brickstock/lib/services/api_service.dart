import 'dart:convert';
// ¡ELIMINADO import 'dart:io'; para no romper Flutter Web!
import 'package:flutter/foundation.dart'; // Necesario para kReleaseMode
import 'package:http/http.dart' as http;
import '../models/lego_theme.dart';
import '../models/lego_set.dart';
import 'auth_service.dart';

class ApiService {
  // 1. Definimos las URLs de los entornos
  // Para Android Emulator deberás usar 'http://10.0.2.2:3000/api' cuando desarrolles en local
  static const String _localUrl = 'http://localhost:3000/api';

  // TODO: Pon aquí tu URL pública de Render cuando la tengas
  static const String _productionUrl =
      'https://brickstock-o9l6.onrender.com/api';

  // 2. Getter estático que decide qué URL usar
  static String get baseUrl {
    if (kReleaseMode) {
      // Si compilamos para Producción (GitHub Pages), usa la de Render
      return _productionUrl;
    }
    // Si estamos en Debug (Desarrollo), usa Localhost
    return _localUrl;
  }

  Future<List<LegoTheme>> getThemes() async {
    // Usamos ApiService.baseUrl directamente para evitar problemas de scope
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/lego/themes'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.map((e) => LegoTheme.fromJson(e)).toList();
    } else {
      debugPrint("Error Backend: ${response.statusCode} - ${response.body}");
      throw Exception('Fallo al cargar temas desde el Backend');
    }
  }

  Future<List<LegoSet>> getSetsByTheme(int themeId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/lego/sets/$themeId'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.map((e) => LegoSet.fromJson(e)).toList();
    } else {
      throw Exception('Fallo al cargar sets desde el Backend');
    }
  }

  Future<String?> getThemeCover(int themeId) async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/lego/themes/$themeId/cover');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'];
      }
    } catch (e) {
      debugPrint('Error fetching theme cover: $e');
    }
    return null;
  }

  String getProxyUrl(String originalUrl) {
    return '${ApiService.baseUrl}/lego/image-proxy?url=${Uri.encodeComponent(originalUrl)}';
  }

  Future<bool> addToCollection(String setNum, double purchasePrice) async {
    final token = await AuthService().getToken();

    if (token == null) throw Exception("Usuario no autenticado");

    final url = Uri.parse('${ApiService.baseUrl}/collection');

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
          'quantity': 1,
          'condition': 'NISB',
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        debugPrint("Error del server: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Error de red: $e");
      return false;
    }
  }
}
