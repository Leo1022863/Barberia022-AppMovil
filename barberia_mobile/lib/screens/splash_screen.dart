import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';
import 'cliente/home_screen.dart';
import 'barbero/agenda_screen.dart';
import 'admin/dashboard_screen.dart';

/// Pantalla inicial que decide automáticamente a dónde navegar
/// según la existencia de una sesión guardada.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _verificarSesion();
  }

  /// Verifica si existe un token JWT almacenado y redirige
  /// al módulo correspondiente según el rol.
  Future<void> _verificarSesion() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('user_token');
    final rol = prefs.getString('user_rol');

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // No existe sesión
    if (token == null || token.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    // Existe sesión
    switch (rol?.toLowerCase()) {
      case 'barbero':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AgendaBarberoScreen()),
        );
        break;

      case 'administrador':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
        break;

      default:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.content_cut, size: 80, color: Colors.indigo),
            SizedBox(height: 20),
            Text(
              'Barbería App',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
