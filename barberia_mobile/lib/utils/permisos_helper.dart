import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Utilidad centralizada para solicitar permisos del dispositivo,
/// gestionando explícitamente los 4 estados que puede devolver el
/// sistema operativo: concedido, denegado, denegado permanentemente,
/// y restringido (bloqueado por políticas externas al usuario).
class PermisosHelper {
  /// Diálogo de explicación mostrado ANTES de la solicitud real al
  /// sistema operativo, tal como exige la guía del taller.
  static Future<bool> _mostrarExplicacion(
    BuildContext context, {
    required String titulo,
    required String mensaje,
  }) async {
    final aceptar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ahora no'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    return aceptar ?? false;
  }

  /// Diálogo específico para el estado de denegación PERMANENTE, con
  /// acceso directo a los ajustes del sistema mediante openAppSettings().
  static Future<void> _mostrarDialogoAjustes(
    BuildContext context, {
    required String mensaje,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permiso deshabilitado'),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings(); // Abre la pantalla de ajustes de ESTA app
            },
            child: const Text('Abrir Ajustes'),
          ),
        ],
      ),
    );
  }

  /// Solicita un permiso gestionando sus 4 estados posibles. Retorna
  /// `true` únicamente si quedó CONCEDIDO; en cualquier otro caso ya se
  /// encargó de mostrar el mensaje o diálogo correspondiente y retorna
  /// `false`, para que la pantalla que llama decida la degradación
  /// (ej. ofrecer una alternativa sin permiso).
  static Future<bool> solicitarPermiso(
    BuildContext context,
    Permission permiso, {
    required String tituloExplicacion,
    required String mensajeExplicacion,
    required String mensajeDenegadoPermanente,
  }) async {
    final continuar = await _mostrarExplicacion(
      context,
      titulo: tituloExplicacion,
      mensaje: mensajeExplicacion,
    );
    if (!continuar || !context.mounted) return false;

    final estado = await permiso.request();

    switch (estado) {
      case PermissionStatus.granted:
        // Estado 1: CONCEDIDO
        return true;

      case PermissionStatus.denied:
        // Estado 2: DENEGADO (se puede volver a pedir más adelante)
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Permiso denegado. Puedes intentarlo de nuevo cuando quieras.',
              ),
            ),
          );
        }
        return false;

      case PermissionStatus.permanentlyDenied:
        // Estado 3: DENEGADO PERMANENTEMENTE (marcó "no volver a preguntar")
        if (context.mounted) {
          await _mostrarDialogoAjustes(
            context,
            mensaje: mensajeDenegadoPermanente,
          );
        }
        return false;

      case PermissionStatus.restricted:
        // Estado 4: RESTRINGIDO (control parental / política del dispositivo,
        // no depende de la decisión del usuario dentro de la app)
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Este permiso está restringido por el sistema en tu dispositivo.',
              ),
            ),
          );
        }
        return false;

      default:
        return false;
    }
  }
}
