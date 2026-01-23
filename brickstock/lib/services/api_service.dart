import 'dart:convert';
import 'dart:io'; // Necesario para detectar la plataforma
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:http/http.dart' as http;
import '../models/lego_theme.dart';
import '../models/lego_set.dart';

class ApiService {
  // Determinamos la URL base según dónde estemos corriendo
  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:3000/api/lego';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000/api/lego';
    return 'http://localhost:3000/api/lego'; // iOS
  }

  // NOTA: Ya no necesitamos _apiKey aquí. ¡Seguridad mejorada!

  Future<List<LegoTheme>> getThemes() async {
    // Fíjate que la ruta ahora coincide con tu backend: /themes
    final response = await http.get(Uri.parse('$_baseUrl/themes'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Rebrickable devuelve { count: ..., results: [...] }
      // Tu backend está devolviendo exactamente lo que da Rebrickable, así que accedemos a 'results'
      final List results = data['results']; 
      return results.map((e) => LegoTheme.fromJson(e)).toList();
    } else {
      throw Exception('Fallo al cargar temas desde el Backend');
    }
  }

  Future<List<LegoSet>> getSetsByTheme(int themeId) async {
    // Ruta backend: /sets/:themeId
    final response = await http.get(Uri.parse('$_baseUrl/sets/$themeId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.map((e) => LegoSet.fromJson(e)).toList();
    } else {
      throw Exception('Fallo al cargar sets desde el Backend');
    }
  }
}