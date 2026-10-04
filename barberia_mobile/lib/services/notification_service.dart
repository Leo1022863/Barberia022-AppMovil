import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Servicio centralizado para la gestión de notificaciones locales.
///
/// Toda la aplicación utilizará esta clase para:
///
/// - Inicializar el plugin.
/// - Solicitar permisos.
/// - Mostrar notificaciones.
/// - Programar recordatorios.
class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Inicializa el sistema de notificaciones.
  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(settings);
  }

  /// Muestra una notificación inmediata.
  static Future<void> mostrarNotificacion({
    required String titulo,
    required String mensaje,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'barberia022_channel',
          'Barberia022',
          channelDescription: 'Canal principal de notificaciones',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(0, titulo, mensaje, details);
  }
}
