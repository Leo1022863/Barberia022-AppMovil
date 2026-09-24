import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/api_service.dart';
import '../utils/permisos_helper.dart';

/// Widget reutilizable: muestra el avatar del usuario y permite
/// actualizarlo. Capacidad nativa PRINCIPAL: cámara (requiere permiso).
/// Vía de DEGRADACIÓN: galería del sistema (no requiere ningún permiso
/// declarado), disponible siempre que la cámara no lo esté.
class FotoPerfilSelector extends StatefulWidget {
  final String? fotoActualUrl; // Ruta relativa devuelta por el backend

  const FotoPerfilSelector({super.key, this.fotoActualUrl});

  @override
  State<FotoPerfilSelector> createState() => _FotoPerfilSelectorState();
}

class _FotoPerfilSelectorState extends State<FotoPerfilSelector> {
  File? _imagenSeleccionada;
  bool _subiendo = false;

  /// Abre un menú inferior para que el usuario elija cómo quiere obtener
  /// la foto: cámara (con permiso) o galería (sin permiso, degradación).
  void _mostrarOpciones() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _tomarFotoConCamara();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de galería'),
              onTap: () {
                Navigator.pop(context);
                _elegirDeGaleria();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Flujo con permiso: solicita CAMERA gestionando los 4 estados vía
  /// PermisosHelper. Solo si queda CONCEDIDO se abre la cámara nativa.
  Future<void> _tomarFotoConCamara() async {
    final concedido = await PermisosHelper.solicitarPermiso(
      context,
      Permission.camera,
      tituloExplicacion: 'Acceso a la cámara',
      mensajeExplicacion: 'Usaremos tu cámara para tomar la foto que se mostrará en tu perfil de Barbería App.',
      mensajeDenegadoPermanente:
          'Deshabilitaste el permiso de cámara con la opción "No volver a preguntar". '
          'Actívalo desde los ajustes del sistema, o usa "Elegir de galería" como alternativa.',
    );

    if (!concedido) return; // El helper ya mostró el aviso correspondiente.

    final XFile? foto = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 70, // Comprime la imagen para no subir archivos pesados
    );

    if (foto != null) {
      setState(() => _imagenSeleccionada = File(foto.path));
      _subirImagen();
    }
  }

  /// Vía de degradación: el selector de GALERÍA del sistema no requiere
  /// declarar ni solicitar ningún permiso (Android 13+/iOS), por lo que
  /// SIEMPRE está disponible como alternativa cuando la cámara no lo está.
  Future<void> _elegirDeGaleria() async {
    final XFile? foto = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (foto != null) {
      setState(() => _imagenSeleccionada = File(foto.path));
      _subirImagen();
    }
  }

  /// Sube la imagen al backend. La ruta relativa devuelta se persiste
  /// localmente dentro de ApiService.subirFotoPerfil (SharedPreferences),
  /// integrando esta capacidad nativa con el backend y el almacenamiento
  /// local, tal como exige el punto 6 de la guía.
  Future<void> _subirImagen() async {
    if (_imagenSeleccionada == null) return;

    setState(() => _subiendo = true);
    final resultado = await ApiService.subirFotoPerfil(_imagenSeleccionada!);
    if (!mounted) return;
    setState(() => _subiendo = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(resultado['message'] ?? ''),
        backgroundColor: resultado['success'] == true
            ? Colors.green
            : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imagenAMostrar;
    if (_imagenSeleccionada != null) {
      imagenAMostrar = FileImage(_imagenSeleccionada!);
    } else if (widget.fotoActualUrl != null &&
        widget.fotoActualUrl!.isNotEmpty) {
      print('FOTO PERFIL: ${widget.fotoActualUrl}');
      imagenAMostrar = NetworkImage(
        'http://192.168.110.221:5000${widget.fotoActualUrl}',
      );
    }

    return GestureDetector(
      onTap: _mostrarOpciones,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.indigo.shade100,
            backgroundImage: imagenAMostrar,
            child: imagenAMostrar == null
                ? const Icon(Icons.person, size: 45, color: Colors.indigo)
                : null,
          ),
          if (_subiendo)
            const Positioned.fill(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.indigo,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
