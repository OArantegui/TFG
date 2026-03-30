import 'dart:convert';
// ¡ELIMINADO import 'dart:io'; para no romper Flutter Web!
import 'package:flutter/foundation.dart'; // Necesario para kReleaseMode
import 'package:http/http.dart' as http;
import '../models/lego_theme.dart';
import '../models/lego_set.dart';
import '../models/collection_item.dart';
import 'auth_service.dart';

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
    // Asegúrate de que esta URL coincida con cómo la tienes en tu servidor Node.
    // Ej: /lego/themes/$themeId/sets 
    String url = '${ApiService.baseUrl}/lego/themes/$themeId/sets?page=$page';
    if (search.isNotEmpty) {
      url += '&search=${Uri.encodeComponent(search)}';
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // Rebrickable devuelve la lista en bruto dentro de 'results'
      final List results = data['results'] ?? [];
      
      // Mapeamos los datos a nuestra clase LegoSet aquí para no romper el HomeScreen
      final List<LegoSet> sets = results.map((e) => LegoSet(
        setNum: e['set_num'],
        name: e['name'],
        year: e['year'],
        themeId: e['theme_id'],
        numParts: e['num_parts'],
        imgUrl: e['set_img_url'] ?? '',
      )).toList();

      // Devolvemos los sets y los metadatos de paginación
      return {
        'sets': sets,
        'count': data['count'] ?? 0,
        'next': data['next'], // Si Rebrickable devuelve una URL aquí, hay más páginas
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

  Future<List<CollectionItem>> getUserCollection() async {
    final token = await AuthService().getToken();
    if (token == null) throw Exception("Usuario no autenticado");

    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/collection'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results =
          data['data']; // 'data' es la key que hemos usado en Node
      return results.map((e) => CollectionItem.fromJson(e)).toList();
    } else {
      throw Exception('Fallo al cargar la colección');
    }
  }

  Future<bool> deleteFromCollection(String collectionId) async {
    final token = await AuthService().getToken();
    if (token == null) return false;

    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/collection/$collectionId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  // AÑADIR A WISHLIST (Devuelve Map para poder leer el 'warning')
  Future<Map<String, dynamic>> addToWishlist(
    String setNum,
    double price, {
    bool force = false,
  }) async {
    final token = await AuthService().getToken();
    if (token == null) return {'success': false, 'message': 'No autenticado'};

    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/wishlist'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'setNum': setNum, 'price': price, 'force': force}),
    );
    return json.decode(response.body);
  }

  // OBTENER WISHLIST COMPLETA
  Future<Map<String, dynamic>> getWishlistData() async {
    final token = await AuthService().getToken();
    if (token == null) throw Exception("Usuario no autenticado");

    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/wishlist'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Fallo al cargar la lista de deseados');
    }
  }

  // ACTUALIZAR PRESUPUESTO
  Future<bool> updateWishlistBudget(double newBudget) async {
    final token = await AuthService().getToken();
    if (token == null) return false;

    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/wishlist/budget'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'newBudget': newBudget}),
    );
    return response.statusCode == 200;
  }

  // BORRAR DE WISHLIST (Similar al de Collection)
  Future<bool> deleteFromWishlist(String id) async {
    final token = await AuthService().getToken();
    if (token == null) return false;
    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/wishlist/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }
}
