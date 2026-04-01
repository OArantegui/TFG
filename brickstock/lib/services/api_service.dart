import 'dart:convert';
// ¡ELIMINADO import 'dart:io'; para no romper Flutter Web!
import 'package:flutter/foundation.dart'; // Necesario para kReleaseMode
import 'package:http/http.dart' as http;
import '../models/lego_theme.dart';
import '../models/lego_set.dart';
import '../models/collection_item.dart';
import 'auth_service.dart';
import '../models/minifigure.dart';
import '../models/achievement.dart';

class ApiService {
  // 1. Definimos las URLs de los entornos
  // Para Android Emulator deberás usar 'http://10.0.2.2:3000/api' cuando desarrolles en local
  //static const String _localUrl = 'http://localhost:3000/api';
  static const String _localUrl = 'http://10.44.44.99:3000/api';

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

  Future<http.Response> _authRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final authService = AuthService();
    String? token = await authService.getAccessToken();

    // Función auxiliar para preparar la petición
    Future<http.Response> makeRequest(String currentToken) {
      final uri = Uri.parse('${ApiService.baseUrl}$endpoint');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $currentToken',
      };

      if (method == 'GET') return http.get(uri, headers: headers);
      if (method == 'POST') return http.post(uri, headers: headers, body: jsonEncode(body));
      if (method == 'PUT') return http.put(uri, headers: headers, body: jsonEncode(body));
      if (method == 'DELETE') return http.delete(uri, headers: headers);
      throw Exception('Método HTTP no soportado');
    }

    // 1. Primer intento
    http.Response response = await makeRequest(token ?? '');

    // 2. Si el token expiró (401 o 403)
    if (response.statusCode == 401 || response.statusCode == 403) {
      print("⚠️ Token expirado. Intentando refrescar de fondo...");
      bool refreshed = await authService.refreshAccessToken();
      
      if (refreshed) {
        // 3. ¡Éxito! Obtenemos el nuevo token y reintentamos la petición original
        token = await authService.getAccessToken();
        print("✅ Token refrescado. Reintentando petición...");
        response = await makeRequest(token!);
      } else {
        // Si no se pudo refrescar (expiró también el largo), se fuerza el logout
        print("❌ Imposible refrescar. Redirigir a Login.");
        // Opcional: Aquí podrías lanzar un evento global para mandar a LoginScreen
        throw Exception("Sesión expirada"); 
      }
    }

    return response;
  }

  Future<Map<String, dynamic>> getThemes({int page = 1, String search = '', String sort = 'name_asc'}) async {
    String url = '${ApiService.baseUrl}/lego/themes?page=$page&sort=$sort';
    if (search.isNotEmpty) {
      url += '&search=${Uri.encodeComponent(search)}';
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body); // Devolvemos todo el mapa (results, totalPages, etc)
    } else {
      throw Exception('Fallo al cargar temas desde el Backend');
    }
  }

  Future<Map<String, dynamic>> getSetsByTheme(int themeId, {int page = 1, String search = ''}) async {
    // ¡ATENCIÓN A ESTA LÍNEA! Es la que estaba dando el error 404.
    String url = '${ApiService.baseUrl}/lego/sets/$themeId?page=$page';
    
    if (search.isNotEmpty) {
      url += '&search=${Uri.encodeComponent(search)}';
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      final List results = data['results'] ?? [];
      
      final List<LegoSet> sets = results.map((e) => LegoSet(
        setNum: e['set_num'],
        name: e['name'],
        year: e['year'],
        themeId: e['theme_id'],
        numParts: e['num_parts'],
        imgUrl: e['set_img_url'] ?? '',
      )).toList();

      return {
        'sets': sets,
        'count': data['count'] ?? 0,
        'next': data['next'], 
      };
    } else {
      throw Exception('Fallo al cargar sets del tema');
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

  Future<Map<String, dynamic>> addToCollection(String setNum, double purchasePrice) async {
    try {
      // Usamos el wrapper, pasándole directamente el método, la ruta y el body
      final response = await _authRequest(
        'POST', 
        '/collection',
        body: {
          'setNum': setNum,
          'purchasePrice': purchasePrice,
          'quantity': 1,
          'condition': 'NISB',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'newAchievements': data['newAchievements'] 
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'Error del servidor'};
      }
    } catch (e) {
      // Si el interceptor falla (ej. expiró la sesión y el refresh token), caerá aquí
      return {'success': false, 'message': 'Error de red o sesión expirada: $e'};
    }
  }

  Future<List<CollectionItem>> getUserCollection() async {
    final response = await _authRequest('GET', '/collection'); // Usamos nuestro wrapper

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['data'];
      return results.map((e) => CollectionItem.fromJson(e)).toList();
    } else {
      throw Exception('Fallo al cargar la colección');
    }
  }

  Future<bool> deleteFromCollection(String collectionId) async {
    try {
      final response = await _authRequest('DELETE', '/collection/$collectionId');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // AÑADIR A WISHLIST (Devuelve Map para poder leer el 'warning')
  Future<Map<String, dynamic>> addToWishlist(
    String setNum,
    double price, {
    bool force = false,
  }) async {
    try {
      final response = await _authRequest(
        'POST',
        '/wishlist',
        body: {'setNum': setNum, 'price': price, 'force': force},
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error de red o sesión expirada'};
    }
  }

  // OBTENER WISHLIST COMPLETA
  Future<Map<String, dynamic>> getWishlistData() async {
    final response = await _authRequest('GET', '/wishlist');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Fallo al cargar la lista de deseados');
    }
  }

  // ACTUALIZAR PRESUPUESTO
  Future<bool> updateWishlistBudget(double newBudget) async {
    try {
      final response = await _authRequest(
        'PUT',
        '/wishlist/budget',
        body: {'newBudget': newBudget},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // BORRAR DE WISHLIST (Similar al de Collection)
  Future<bool> deleteFromWishlist(String id) async {
    try {
      final response = await _authRequest('DELETE', '/wishlist/$id');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<Minifigure>> getSetMinifigures(String setNum) async {
    try {
      // Usamos el endpoint que hemos creado en nuestro propio backend Node
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/lego/sets/$setNum/minifigs'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success']) {
          List<dynamic> data = jsonResponse['data'];
          return data.map((json) => Minifigure.fromJson(json)).toList();
        } else {
          throw Exception('Error del servidor: ${jsonResponse['message']}');
        }
      } else {
        throw Exception('Fallo al cargar minifiguras');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
  Future<List<LegoSet>> getMinifigSets(String figNum) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/lego/minifigs/$figNum/sets')
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success']) {
          List<dynamic> data = jsonResponse['data'];
          // Reutilizamos tu modelo LegoSet directamente
          return data.map((e) => LegoSet(
            setNum: e['setNum'] ?? '',
            name: e['name'] ?? 'Desconocido',
            year: e['year'] ?? 0,
            themeId: e['themeId'] ?? 0,
            numParts: e['numParts'] ?? 0,
            imgUrl: e['imageUrl'] ?? '',
          )).toList();
        } else {
          throw Exception('Error del servidor: ${jsonResponse['message']}');
        }
      } else {
        throw Exception('Fallo al cargar sets de la minifigura');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
  
  Future<Map<String, dynamic>> getAllSets({int page = 1, String search = ''}) async {
    String url = '${ApiService.baseUrl}/lego/sets?page=$page';
    
    if (search.isNotEmpty) {
      url += '&search=${Uri.encodeComponent(search)}';
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'] ?? [];
      
      final List<LegoSet> sets = results.map((e) => LegoSet(
        setNum: e['set_num'],
        name: e['name'],
        year: e['year'],
        themeId: e['theme_id'],
        numParts: e['num_parts'],
        imgUrl: e['set_img_url'] ?? '',
      )).toList();

      return {
        'sets': sets,
        'count': data['count'] ?? 0,
        'next': data['next'], 
      };
    } else {
      throw Exception('Fallo al cargar todos los sets');
    }
  }

  // Obtener todo el catálogo de logros del usuario
  Future<List<Achievement>> getMyAchievements() async {
    final response = await _authRequest('GET', '/achievements');

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success']) {
        List<dynamic> data = jsonResponse['data'];
        return data.map((json) => Achievement.fromJson(json as Map<String, dynamic>)).toList();
      }
    }
    throw Exception('Fallo al cargar las insignias');
  }
  Future<Map<String, dynamic>> getAllMinifigs({int page = 1, String search = ''}) async {
    String url = '${ApiService.baseUrl}/lego/minifigs?page=$page';
    if (search.isNotEmpty) {
      url += '&search=${Uri.encodeComponent(search)}';
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        final results = data['data']['results'] ?? [];
        final minifigs = results.map<Minifigure>((e) => Minifigure.fromJson(e)).toList();
        return {
          'minifigs': minifigs,
          'count': data['data']['count'] ?? 0,
          'next': data['data']['next'],
        };
      }
      throw Exception('Error en el formato de datos de minifiguras');
    } else {
      throw Exception('Fallo al cargar todas las minifiguras');
    }
  }

  // 2. Obtener detalles de una minifigura (Para la nueva pantalla de detalles)
  Future<Map<String, dynamic>> getMinifigDetails(String figNum) async {
    final response = await http.get(Uri.parse('${ApiService.baseUrl}/lego/minifigs/$figNum'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data['data']; // Devolvemos el json enriquecido con 'appearsInSets'
      }
      throw Exception('Error en los detalles de la minifigura');
    } else {
      throw Exception('Fallo al cargar detalles de la minifigura');
    }
  }

  // 3. Obtener la colección de minifiguras del usuario (Para la pestaña Colección)
  Future<List<Minifigure>> getUserMinifigCollection() async {
    // Usamos el wrapper con Token JWT
    final response = await _authRequest('GET', '/collection/minifigs');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        final List results = data['data'];
        return results.map((e) => Minifigure.fromJson(e)).toList();
      }
      throw Exception('Error al parsear cartera de minifiguras');
    } else {
      throw Exception('Fallo al cargar la colección de minifiguras');
    }
  }

  // 4. Añadir una minifigura suelta a la colección
  Future<Map<String, dynamic>> addMinifigToCollection(String figNum, {int quantity = 1}) async {
    try {
      final response = await _authRequest(
        'POST',
        '/collection/minifigs',
        body: {
          'figNum': figNum,
          'quantity': quantity,
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Error del servidor'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de red o sesión expirada: $e'};
    }
  }
}

