import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../login_screen.dart';

/// Pantalla principal del rol Barbero. Muestra todas las citas que le
/// han sido asignadas (consumiendo GET /api/citas/mis-citas-barbero) y
/// permite actualizar el estado de cada una (Pendiente -> Confirmada ->
/// Completada, o Cancelada) directamente desde la app, sin depender
/// de la versión web.
class AgendaBarberoScreen extends StatefulWidget {
  const AgendaBarberoScreen({super.key});

  @override
  State<AgendaBarberoScreen> createState() => _AgendaBarberoScreenState();
}

class _AgendaBarberoScreenState extends State<AgendaBarberoScreen> {
  List<dynamic> _citas = [];
  bool _isLoading = true;

  // Lista de estados posibles, en el mismo orden del flujo natural de
  // una cita. Se usa para construir el menú desplegable de cada tarjeta.
  final List<String> _estadosDisponibles = [
    'Pendiente',
    'Confirmada',
    'Completada',
    'Cancelada',
  ];

  @override
  void initState() {
    super.initState();
    _cargarAgenda();
  }

  /// Solicita al backend la lista de citas asignadas al barbero
  /// autenticado. Se reutiliza tanto en initState como en el
  /// pull-to-refresh y después de actualizar un estado.
  Future<void> _cargarAgenda() async {
    setState(() => _isLoading = true);

    final citas = await ApiService.getCitasBarbero();

    if (!mounted) return;

    setState(() {
      _citas = citas;
      _isLoading = false;
    });
  }

  /// Envía el nuevo estado seleccionado al backend. Si la actualización
  /// fue exitosa, recarga la agenda completa para reflejar el cambio;
  /// si falló (por ejemplo, la cita ya no pertenece a este barbero),
  /// muestra el mensaje de error devuelto por el servidor.
  Future<void> _cambiarEstado(int idCita, String nuevoEstado) async {
    final resultado = await ApiService.actualizarEstadoCita(
      idCita: idCita,
      nuevoEstado: nuevoEstado,
    );

    if (!mounted) return;

    if (resultado['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['message'] ?? 'Estado actualizado'),
          backgroundColor: Colors.green,
        ),
      );
      await _cargarAgenda(); // Refresca la lista para mostrar el nuevo estado
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resultado['message'] ?? 'No se pudo actualizar la cita',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Limpia la sesión guardada y regresa a LoginScreen, eliminando todo
  /// el historial de navegación previo (igual que en HomeScreen del Cliente).
  Future<void> _cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  /// Traduce el estado textual a un color distintivo, igual que en
  /// MisCitasScreen del cliente, para mantener consistencia visual
  /// en toda la app.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Agenda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _citas.isEmpty
          // Estado vacío: el barbero todavía no tiene citas asignadas.
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_available,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No tienes citas asignadas por ahora.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          // RefreshIndicator: deslizar hacia abajo recarga la agenda,
          // útil si un cliente reserva mientras el barbero tiene la
          // app abierta.
          : RefreshIndicator(
              onRefresh: _cargarAgenda,
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _citas.length,
                itemBuilder: (context, index) {
                  final cita = _citas[index];
                  final estadoActual = cita['estado'] ?? 'Pendiente';
                  final color = _colorPorEstado(estadoActual);

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
                          // Fila superior: nombre del cliente + servicio.
                          Row(
                            children: [
                              const Icon(
                                Icons.person,
                                size: 18,
                                color: Colors.indigo,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  cita['cliente'] ?? 'Cliente',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.content_cut,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(cita['servicio'] ?? 'Servicio'),
                            ],
                          ),
                          const SizedBox(height: 4),
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
                          // Notas del cliente, solo si escribió alguna.
                          if ((cita['notas'] ?? '')
                              .toString()
                              .trim()
                              .isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Nota: ${cita['notas']}',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          // Fila inferior: chip de estado actual + menú
                          // desplegable para cambiarlo. El DropdownButton
                          // muestra el estado actual como valor seleccionado
                          // y dispara _cambiarEstado al elegir uno distinto.
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Chip(
                                label: Text(
                                  estadoActual,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor: color,
                              ),
                              DropdownButton<String>(
                                value: estadoActual,
                                underline:
                                    const SizedBox(), // sin línea inferior fea
                                items: _estadosDisponibles.map((estado) {
                                  return DropdownMenuItem(
                                    value: estado,
                                    child: Text(estado),
                                  );
                                }).toList(),
                                onChanged: (nuevoEstado) {
                                  if (nuevoEstado != null &&
                                      nuevoEstado != estadoActual) {
                                    _cambiarEstado(
                                      cita['id_cita'],
                                      nuevoEstado,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
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
