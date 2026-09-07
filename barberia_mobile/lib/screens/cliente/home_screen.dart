import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../login_screen.dart';
import 'reserva_screen.dart';
import 'mis_citas_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Variables de estado local para los datos del usuario y la lista de elementos
  String _nombreUsuario = '';
  List<dynamic> _servicios = [];
  List<dynamic> _barberos = [];
  bool _isLoading = true;

  // Variables para almacenar las selecciones del usuario (IDs)
  int? _servicioSeleccionadoId;
  int? _barberoSeleccionadoId;

  @override
  void initState() {
    super.initState();
    // Carga de datos al inicializar la pantalla principal
    _cargarDatos();
  }

  // Carga los datos guardados en SharedPreferences y realiza las peticiones HTTP al backend
  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    final nombre = prefs.getString('user_nombre') ?? 'Cliente';

    // Llamadas asíncronas para obtener catálogos de la API
    final servicios = await ApiService.getServicios();
    final barberos = await ApiService.getBarberos();

    // Actualización del estado visual
    setState(() {
      _nombreUsuario = nombre;
      _servicios = servicios;
      _barberos = barberos;
      _isLoading = false;
    });
  }

  // Limpia la sesión y vuelve a la pantalla de Login
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bienvenido, $_nombreUsuario'),
        actions: [
          //: acceso rápido al historial de citas del cliente.
          IconButton(
            icon: const Icon(Icons.event_note),
            tooltip: 'Mis Citas',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MisCitasScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            ) // Spinner mientras cargan los datos
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- SECCIÓN 1: SELECCIÓN DE SERVICIO ---
                  const Text(
                    '1. Selecciona un Servicio',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  _servicios.isEmpty
                      ? const Text(
                          'No hay servicios disponibles en este momento.',
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _servicios.length,
                          itemBuilder: (context, index) {
                            final servicio = _servicios[index];
                            // Determina si esta tarjeta específica está seleccionada
                            final esSeleccionado =
                                _servicioSeleccionadoId ==
                                servicio['id_servicio'];

                            return Card(
                              color: esSeleccionado
                                  ? Colors.indigo.shade50
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: esSeleccionado
                                      ? Colors.indigo
                                      : Colors.grey.shade300,
                                  width: esSeleccionado ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.content_cut,
                                  color: Colors.indigo,
                                ),
                                title: Text(
                                  servicio['nombre_servicio'] ?? 'Servicio',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${servicio['descripcion'] ?? ''}\nDuración: ${servicio['duracion_minutos'] ?? '30'} min',
                                ),
                                trailing: Text(
                                  '\$${servicio['precio'] ?? '0.00'}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                onTap: () {
                                  // Cambia el ID del servicio seleccionado al hacer clic
                                  setState(() {
                                    _servicioSeleccionadoId =
                                        servicio['id_servicio'];
                                  });
                                },
                              ),
                            );
                          },
                        ),

                  const SizedBox(height: 25),

                  // --- SECCIÓN 2: SELECCIÓN DE BARBERO ---
                  const Text(
                    '2. Selecciona tu Barbero',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  _barberos.isEmpty
                      ? const Text('No hay barberos disponibles.')
                      : SizedBox(
                          height:
                              120, // Altura fija para el carrusel horizontal
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _barberos.length,
                            itemBuilder: (context, index) {
                              final barbero = _barberos[index];
                              // Determina si esta tarjeta de barbero está seleccionada
                              final esSeleccionado =
                                  _barberoSeleccionadoId ==
                                  barbero['id_usuario'];

                              return GestureDetector(
                                onTap: () {
                                  // Cambia el ID del barbero seleccionado
                                  setState(() {
                                    _barberoSeleccionadoId =
                                        barbero['id_usuario'];
                                  });
                                },
                                child: Container(
                                  width: 100,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: esSeleccionado
                                        ? Colors.indigo.shade100
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: esSeleccionado
                                          ? Colors.indigo
                                          : Colors.grey.shade300,
                                      width: esSeleccionado ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.indigo,
                                        child: Text(
                                          (barbero['nombre'] ?? 'B')[0]
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        barbero['nombre'] ?? 'Barbero',
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                  const SizedBox(height: 30),

                  // --- BOTÓN ACCIÓN: CONTINUAR ---
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                      // El botón solo se habilita si el cliente ya seleccionó tanto servicio como barbero
                      onPressed:
                          (_servicioSeleccionadoId != null &&
                              _barberoSeleccionadoId != null)
                          ? () {
                              final servicio = _servicios.firstWhere(
                                (s) =>
                                    s['id_servicio'] == _servicioSeleccionadoId,
                              );
                              final barbero = _barberos.firstWhere(
                                (b) =>
                                    b['id_usuario'] == _barberoSeleccionadoId,
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReservaScreen(
                                    servicio: servicio,
                                    barbero: barbero,
                                  ),
                                ),
                              );
                            }
                          : null,
                      child: const Text('Continuar a Fecha y Hora'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
