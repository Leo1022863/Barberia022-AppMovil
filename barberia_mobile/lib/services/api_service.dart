import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  // IP base que apunta al servidor local Flask desde el emulador de Android
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  // --- SERVICIO DE LOGIN ---
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      // Verificación de formato para evitar fallos si el servidor responde con páginas HTML de error
      if (response.headers['content-type']?.contains('text/html') ?? false) {
        return {
          'success': false,
          'message': 'Respuesta HTML inesperada del servidor.',
        };
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error de autenticación',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // CONSULTAR SERVICIOS DESDE LA API
  static Future<List<dynamic>> getServicios() async {
    try {
      // Petición GET al endpoint /api/barberia/servicios
      final response = await http.get(
        Uri.parse('$baseUrl/barberia/servicios'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Decodificación de la lista JSON de servicios devuelta por Flask
        final data = jsonDecode(response.body);
        return data['servicios'] ?? data;
      }
      return [];
    } catch (e) {
      print('Error al obtener la lista de servicios: $e');
      return [];
    }
  }

  //  CONSULTAR BARBEROS DESDE LA API
  static Future<List<dynamic>> getBarberos() async {
    try {
      // Petición GET al endpoint /api/barberia/barberos
      final response = await http.get(
        Uri.parse('$baseUrl/barberia/barberos'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Decodificación de la lista JSON de barberos devuelta por Flask
        final data = jsonDecode(response.body);
        return data['barberos'] ?? data;
      }
      return [];
    } catch (e) {
      print('Error al obtener la lista de barberos: $e');
      return [];
    }
  }
}
