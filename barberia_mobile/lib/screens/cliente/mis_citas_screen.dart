import 'package:flutter/material.dart';

import '../../services/api_service.dart';

/// Pantalla de historial de citas del cliente autenticado.
/// Consume GET /api/citas/mis-citas (protegido por JWT) a través de
/// ApiService.getMisCitas(), que ya extrae el id del cliente desde el
/// propio token, así que aquí no necesitamos pasar ningún parámetro.
class MisCitasScreen extends StatefulWidget {
  const MisCitasScreen({super.key});

  @override
  State<MisCitasScreen> createState() => _MisCitasScreenState();
}

class _MisCitasScreenState extends State<MisCitasScreen> {
  List<dynamic> _citas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarCitas();
  }

  /// Solicita al backend el listado de citas del usuario y actualiza
  /// el estado visual. Se usa tanto en initState como en el pull-to-refresh.
  Future<void> _cargarCitas() async {
    setState(() => _isLoading = true);

    final citas = await ApiService.getMisCitas();

    if (!mounted) return;

    setState(() {
      _citas = citas;
      _isLoading = false;
    });
  }

  /// Traduce el string de estado devuelto por el backend (Pendiente,
  /// Confirmada, Completada, Cancelada) a un color distintivo, para que
  /// el cliente identifique de un vistazo la situación de cada cita.
  Color _colorPorEstado(String estado) {
    switch (estado) {
      case 'Confirmada':
        return Colors.blue;
      case 'Completada':
        return Colors.green;
      case 'Cancelada':
        return Colors.red;
      case 'Pendiente':
      default:
        return Colors.orange;
    }
  }

  /// Devuelve un ícono representativo según el estado, reforzando
  /// visualmente la información además del color.
  IconData _iconoPorEstado(String estado) {
    switch (estado) {
      case 'Confirmada':
        return Icons.event_available;
      case 'Completada':
        return Icons.check_circle;
      case 'Cancelada':
        return Icons.cancel;
      case 'Pendiente':
      default:
        return Icons.hourglass_top;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Citas')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _citas.isEmpty
          // Estado vacío: el cliente aún no tiene citas registradas.
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text(
                    'Todavía no tienes citas agendadas.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          // RefreshIndicator permite deslizar hacia abajo para
          // recargar el historial (útil si el barbero cambió el
          // estado de una cita mientras el cliente estaba en la app).
          : RefreshIndicator(
              onRefresh: _cargarCitas,
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _citas.length,
                itemBuilder: (context, index) {
                  final cita = _citas[index];
                  final estado = cita['estado'] ?? 'Pendiente';
                  final color = _colorPorEstado(estado);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: color.withOpacity(0.4)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Fila superior: nombre del servicio + chip de estado.
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  cita['servicio'] ?? 'Servicio',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Chip(
                                avatar: Icon(
                                  _iconoPorEstado(estado),
                                  size: 16,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  estado,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor: color,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Fecha y hora de la cita.
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${cita['fecha_cita']}  •  ${cita['hora_cita']}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Barbero asignado.
                          Row(
                            children: [
                              const Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(cita['barbero'] ?? 'No asignado'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Precio del servicio.
                          Row(
                            children: [
                              const Icon(
                                Icons.attach_money,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text('\$${cita['precio'] ?? '0.00'}'),
                            ],
                          ),
                          // Notas, solo si el cliente escribió alguna.
                          if ((cita['notas'] ?? '')
                              .toString()
                              .trim()
                              .isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Nota: ${cita['notas']}',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
