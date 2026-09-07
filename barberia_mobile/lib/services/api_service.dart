import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // IP base que apunta al servidor local Flask desde el emulador de Android
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  // Recupera el token JWT guardado localmente tras el login
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_token');
  }

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

      if (response.headers['content-type']?.contains('text/html') ?? false) {
        return {
          'success': false,
          'message': 'Respuesta HTML inesperada del servidor.',
        };
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Persistimos la sesión: token JWT + datos básicos del usuario
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_token', data['access_token'] ?? '');
        await prefs.setString(
          'user_nombre',
          data['user']?['nombre'] ?? 'Cliente',
        );
        await prefs.setInt('user_id', data['user']?['id_usuario'] ?? 0);
        //guardamos el rol para decidir a qué pantalla navegar
        await prefs.setString('user_rol', data['user']?['rol'] ?? 'Cliente');

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

  // --- CONSULTAR SERVICIOS ---
  static Future<List<dynamic>> getServicios() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/servicios'), // <-- corregido, sin "/barberia"
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['servicios'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error al obtener la lista de servicios: $e');
      return [];
    }
  }

  // --- CONSULTAR BARBEROS ---
  static Future<List<dynamic>> getBarberos() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/barberos'), // <-- corregido, sin "/barberia"
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['barberos'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error al obtener la lista de barberos: $e');
      return [];
    }
  }

  // --- NUEVO: CREAR RESERVA (POST /api/citas, protegido por JWT) ---
  static Future<Map<String, dynamic>> crearReserva({
    required int idBarbero,
    required int idServicio,
    required String fechaCita, // formato 'YYYY-MM-DD'
    required String horaCita, // formato 'HH:MM'
    String notas = '',
  }) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Sesión expirada. Vuelve a iniciar sesión.',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/citas'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'id_barbero': idBarbero,
          'id_servicio': idServicio,
          'fecha_cita': fechaCita,
          'hora_cita': horaCita,
          'notas': notas,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'No se pudo agendar la cita',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  //  HISTORIAL DE CITAS DEL CLIENTE ---
  static Future<List<dynamic>> getMisCitas() async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/citas/mis-citas'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['citas'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error al obtener mis citas: $e');
      return [];
    }
  }

  /// --- AGENDA DEL BARBERO ---
  /// Petición GET al endpoint protegido /api/citas/mis-citas-barbero.
  /// Igual que getMisCitas(), el backend identifica al barbero a través
  /// del token JWT, así que no se envía ningún ID manualmente.
  static Future<List<dynamic>> getCitasBarbero() async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/citas/mis-citas-barbero'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['citas'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error al obtener la agenda del barbero: $e');
      return [];
    }
  }

  /// --- ACTUALIZAR ESTADO DE UNA CITA ---
  /// Petición PUT al endpoint protegido /api/citas/id/estado.
  /// El backend valida que la cita pertenezca al barbero autenticado
  /// antes de aplicar el cambio, así que aquí solo enviamos el nuevo
  /// estado deseado.
  static Future<Map<String, dynamic>> actualizarEstadoCita({
    required int idCita,
    required String nuevoEstado,
  }) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Sesión expirada. Vuelve a iniciar sesión.',
        };
      }

      final response = await http.put(
        Uri.parse('$baseUrl/citas/$idCita/estado'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'estado': nuevoEstado}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'No se pudo actualizar el estado',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// --- ADMIN: LISTADO DE USUARIOS ---
  /// Petición GET a /api/usuarios. El backend valida internamente que
  /// quien llama tenga rol Administrador (devuelve 403 si no).
  static Future<List<dynamic>> getUsuarios() async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/usuarios'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['usuarios'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error al obtener usuarios: $e');
      return [];
    }
  }

  /// --- ADMIN: CAMBIAR ROL DE UN USUARIO ---
  static Future<Map<String, dynamic>> actualizarRolUsuario({
    required int idUsuario,
    required String nuevoRol,
  }) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Sesión expirada. Vuelve a iniciar sesión.',
        };
      }

      final response = await http.put(
        Uri.parse('$baseUrl/usuarios/$idUsuario/rol'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'rol': nuevoRol}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'No se pudo actualizar el rol',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// --- ADMIN: TODAS LAS CITAS DE LA BARBERÍA ---
  static Future<List<dynamic>> getTodasLasCitas() async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/citas'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['citas'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error al obtener todas las citas: $e');
      return [];
    }
  }
}
