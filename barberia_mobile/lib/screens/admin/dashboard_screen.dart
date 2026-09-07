import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../login_screen.dart';

/// Panel de Administrador con dos pestañas: gestión de usuarios/roles
/// y una vista global de todas las citas de la barbería. Usa
/// DefaultTabController para mantener la navegación simple sin agregar
/// dependencias externas.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Future<void> _cerrarSesion(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel de Administrador'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _cerrarSesion(context),
              tooltip: 'Cerrar Sesión',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Usuarios'),
              Tab(icon: Icon(Icons.event_note), text: 'Citas'),
            ],
          ),
        ),
        body: const TabBarView(children: [_UsuariosTab(), _CitasTab()]),
      ),
    );
  }
}

/// --- PESTAÑA 1: GESTIÓN DE USUARIOS Y ROLES ---
class _UsuariosTab extends StatefulWidget {
  const _UsuariosTab();

  @override
  State<_UsuariosTab> createState() => _UsuariosTabState();
}

class _UsuariosTabState extends State<_UsuariosTab> {
  List<dynamic> _usuarios = [];
  bool _isLoading = true;

  // Roles fijos del sistema. Coinciden exactamente con los valores
  // guardados en la tabla `roles` (nombre_rol), ya que el backend
  // los compara como texto.
  final List<String> _rolesDisponibles = [
    'Cliente',
    'Barbero',
    'Administrador',
  ];

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    setState(() => _isLoading = true);
    final usuarios = await ApiService.getUsuarios();
    if (!mounted) return;
    setState(() {
      _usuarios = usuarios;
      _isLoading = false;
    });
  }

  /// Envía el cambio de rol al backend y recarga la lista si fue exitoso,
  /// o muestra el motivo del rechazo (ej. "no puedes quitarte tu propio
  /// rol de Administrador").
  Future<void> _cambiarRol(int idUsuario, String nuevoRol) async {
    final resultado = await ApiService.actualizarRolUsuario(
      idUsuario: idUsuario,
      nuevoRol: nuevoRol,
    );

    if (!mounted) return;

    if (resultado['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['message'] ?? 'Rol actualizado'),
          backgroundColor: Colors.green,
        ),
      );
      await _cargarUsuarios();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['message'] ?? 'No se pudo actualizar el rol'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _colorPorRol(String rol) {
    switch (rol) {
      case 'Administrador':
        return Colors.purple;
      case 'Barbero':
        return Colors.indigo;
      case 'Cliente':
      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _cargarUsuarios,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _usuarios.length,
        itemBuilder: (context, index) {
          final usuario = _usuarios[index];
          final rolActual = usuario['rol'] ?? 'Cliente';

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _colorPorRol(rolActual),
                child: Text(
                  (usuario['nombre'] ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text('${usuario['nombre']} ${usuario['apellido']}'),
              subtitle: Text(usuario['email'] ?? ''),
              // Dropdown para reasignar el rol directamente desde la lista,
              // igual al patrón usado en la agenda del barbero.
              trailing: DropdownButton<String>(
                value: rolActual,
                underline: const SizedBox(),
                items: _rolesDisponibles.map((rol) {
                  return DropdownMenuItem(value: rol, child: Text(rol));
                }).toList(),
                onChanged: (nuevoRol) {
                  if (nuevoRol != null && nuevoRol != rolActual) {
                    _cambiarRol(usuario['id_usuario'], nuevoRol);
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

/// --- PESTAÑA 2: VISTA GLOBAL DE CITAS ---
class _CitasTab extends StatefulWidget {
  const _CitasTab();

  @override
  State<_CitasTab> createState() => _CitasTabState();
}

class _CitasTabState extends State<_CitasTab> {
  List<dynamic> _citas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarCitas();
  }

  Future<void> _cargarCitas() async {
    setState(() => _isLoading = true);
    final citas = await ApiService.getTodasLasCitas();
    if (!mounted) return;
    setState(() {
      _citas = citas;
      _isLoading = false;
    });
  }

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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_citas.isEmpty) {
      return const Center(child: Text('No hay citas registradas todavía.'));
    }

    return RefreshIndicator(
      onRefresh: _cargarCitas,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _citas.length,
        itemBuilder: (context, index) {
          final cita = _citas[index];
          final estado = cita['estado'] ?? 'Pendiente';
          final color = _colorPorEstado(estado);

          // Esta pestaña es de solo lectura: el cambio de estado sigue
          // siendo responsabilidad del Barbero desde su propia agenda.
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: color.withOpacity(0.4)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          cita['servicio'] ?? 'Servicio',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Chip(
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
                  const SizedBox(height: 4),
                  Text('${cita['fecha_cita']} • ${cita['hora_cita']}'),
                  const SizedBox(height: 4),
                  Text('Cliente: ${cita['cliente']}'),
                  Text('Barbero: ${cita['barbero']}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
