import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class AuthService {
  //Usamos Secure Storage para tokens y SharedPreferences para datos no sensibles.
  final _secureStorage = const FlutterSecureStorage();

  // GESTIÓN DE TOKENS

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(key: 'access_token', value: accessToken);
    await _secureStorage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access_token');
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: 'refresh_token');
  }

  /// Borra los tokens y llama al Backend para revocar la sesión
  Future<void> logout() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken != null) {
      // Le decimos al backend que destruya este token
      try {
        await http.post(
          Uri.parse('${ApiService.baseUrl}/auth/logout'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refreshToken': refreshToken}),
        );
      } catch (e) {
        print("Error avisando al servidor del logout: $e");
      }
    }

    // Borramos datos locales
    await _secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Comprueba si hay una sesión activa al abrir la app (basta con tener el refresh_token)
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();

    // Comprobamos si el usuario marcó la casilla. Por defecto (si no existe) es true.
    final keepSignedIn = prefs.getBool('keep_signed_in') ?? true;

    // Si NO quería mantener la sesión, destruimos los tokens ahora que ha reabierto la app
    if (!keepSignedIn) {
      await logout();
      return false;
    }

    final token = await getRefreshToken();
    return token != null && token.isNotEmpty;
  }

  // Métodos de UserData
  Future<void> saveUserData(
    String username,
    String email,
    String avatar,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('email', email);
    await prefs.setString('avatar', avatar);
  }

  Future<Map<String, String>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? '',
      'avatar': prefs.getString('avatar') ?? 'assets/avatars/lego-default.jpg',
    };
  }

  //Backend
  Future<bool> login(
    String email,
    String password, {
    bool keepSignedIn = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['accessToken'];
        final refreshToken = data['refreshToken'];
        final user = data['user'];

        if (accessToken != null && refreshToken != null) {
          await saveTokens(accessToken, refreshToken);
          if (user != null) {
            await saveUserData(
              user['username'],
              user['email'],
              user['avatar'] ?? 'assets/avatars/lego-default.jpg',
            );
          }

          //Guardamos la decisión del usuario
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('keep_signed_in', keepSignedIn);

          return true;
        }
      }
      return false;
    } catch (e) {
      print("Error de red en login: $e");
      return false;
    }
  }

  // Registro
  Future<bool> register(
    String username,
    String email,
    String password,
    String avatar, {
    bool keepSignedIn = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'avatar': avatar,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final accessToken = data['accessToken'];
        final refreshToken = data['refreshToken'];
        final user = data['user'];

        if (accessToken != null && refreshToken != null) {
          await saveTokens(accessToken, refreshToken);
          if (user != null)
            await saveUserData(
              user['username'],
              user['email'],
              user['avatar'] ?? avatar,
            );

          // Guardamos la decisión
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('keep_signed_in', keepSignedIn);

          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  //REFRESCAR EL TOKEN

  /// Pide un nuevo Access Token usando el Refresh Token
  Future<bool> refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['accessToken'];

        // Sobrescribimos SOLO el Access Token corto
        await _secureStorage.write(key: 'access_token', value: newAccessToken);
        return true;
      } else {
        // Si el servidor rechaza el refresh token (ha caducado el de 30 días o lo hemos revocado)
        // Forzamos cerrar sesión
        await logout();
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProfile(
    String? username,
    String? email,
    String? password,
  ) async {
    // Aquí podrías usar el nuevo método de ApiService luego, pero de momento:
    try {
      final token = await getAccessToken();
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
        if (data['user'] != null) {
          // Recuperamos los datos actuales por si el backend no manda el avatar
          final currentUserData = await getUserData();
          final currentAvatar = currentUserData['avatar'] ?? 'assets/avatars/lego-default.jpg';

          await saveUserData(
            data['user']['username'], 
            data['user']['email'], 
            data['user']['avatar'] ?? currentAvatar
          );
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> verifyCurrentPassword(String currentPassword) async {
    try {
      final token = await getAccessToken();
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/verify-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'currentPassword': currentPassword}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false; // Si devuelve 400 (incorrecta)
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateAvatar(String avatarPath) async {
    try {
      String? token = await getAccessToken();
      final uri = Uri.parse('${ApiService.baseUrl}/auth/avatar');

      // Función auxiliar para no repetir código de los headers
      Future<http.Response> makeRequest(String currentToken) {
        return http.put(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $currentToken',
          },
          body: jsonEncode({'avatar': avatarPath}),
        );
      }

      // Primer intento
      var response = await makeRequest(token ?? '');

      // Si el token está caducado, forzamos refresco automático
      if (response.statusCode == 401 || response.statusCode == 403) {
        print("Token caducado cambiando avatar. Refrescando...");
        bool refreshed = await refreshAccessToken();
        if (refreshed) {
          token = await getAccessToken();
          // Reintentamos la petición de actualizar avatar con el token nuevo
          response = await makeRequest(token!);
        }
      }

      // Evaluamos el resultado final
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Actualiza los datos locales
        await saveUserData(
          data['user']['username'],
          data['user']['email'],
          data['user']['avatar'],
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
