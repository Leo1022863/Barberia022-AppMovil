import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'cliente/home_screen.dart';
import 'barbero/agenda_screen.dart';
import 'admin/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // GlobalKey que nos permite validar todo el formulario de una sola vez
  // (recorre automáticamente cada TextFormField y ejecuta su validator).
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // Expresión regular para validar formato de correo electrónico:
  // exige texto antes de la @, texto después, un punto y un dominio
  // de al menos 2 caracteres (ej. .com, .co, .es).
  final RegExp _emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');

  /// Valida el campo de correo. Se ejecuta automáticamente por el Form
  /// al llamar _formKey.currentState!.validate(), y también en cada
  /// cambio de texto gracias a AutovalidateMode.onUserInteraction.
  /// Retorna null si es válido, o el mensaje de error a mostrar si no.
  String? _validarEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa tu correo electrónico';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Correo electrónico inválido';
    }
    return null;
  }

  /// Valida el campo de contraseña. Por ahora solo verifica que no esté
  /// vacío; si más adelante quieres exigir longitud mínima, se agrega aquí.
  String? _validarPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa tu contraseña';
    }
    return null;
  }

  /// Ejecuta el flujo de autenticación. Antes de llamar al backend,
  /// valida el formulario completo con _formKey.currentState!.validate().
  /// Si algún campo es inválido, el Form muestra los mensajes de error
  /// automáticamente debajo de cada campo y NO se envía la petición.
  void _ejecutarLogin() async {
    // Si el formulario no es válido, detenemos aquí. validate() ya se
    // encarga de mostrar los mensajes de error en pantalla.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final response = await ApiService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response['success']) {
      final rol = response['data']?['user']?['rol'] ?? 'Cliente';

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Inicio de sesión exitoso!'),
          backgroundColor: Colors.green,
        ),
      );

      Widget pantallaDestino;
      switch (rol.toString().toLowerCase()) {
        case 'barbero':
          pantallaDestino = const AgendaBarberoScreen();
          break;
        case 'administrador':
          pantallaDestino = const AdminDashboardScreen();
          break;
        default:
          pantallaDestino = const HomeScreen();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => pantallaDestino),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(response['message'])));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        // Envolvemos los campos en un Form para poder validarlos en
        // conjunto y mostrar los mensajes de error automáticamente.
        child: Form(
          key: _formKey,
          // onUserInteraction: no muestra errores apenas se abre la
          // pantalla (sería intrusivo), pero SÍ empieza a validar en
          // vivo cada campo desde el momento en que el usuario lo toca
          // o escribe en él por primera vez.
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Barbería App',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              // Campo de correo: ahora es TextFormField con validator.
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: _validarEmail,
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 15),
              // Campo de contraseña: también validado, y sigue ocultando
              // el texto con obscureText.
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                validator: _validarPassword,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _ejecutarLogin,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Iniciar Sesión'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
