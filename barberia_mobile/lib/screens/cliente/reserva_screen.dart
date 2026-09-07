import 'package:flutter/material.dart';

import '../../services/api_service.dart';

/// Pantalla de confirmación de reserva. Recibe el servicio y el barbero
/// ya seleccionados en HomeScreen, y permite al usuario elegir fecha, hora
/// y agregar notas opcionales antes de enviar la cita al backend.
class ReservaScreen extends StatefulWidget {
  final dynamic servicio;
  final dynamic barbero;

  const ReservaScreen({
    super.key,
    required this.servicio,
    required this.barbero,
  });

  @override
  State<ReservaScreen> createState() => _ReservaScreenState();
}

class _ReservaScreenState extends State<ReservaScreen> {
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;
  final _notasController = TextEditingController();
  bool _isLoading = false;

  /// Abre el selector nativo de fecha (calendario) de Flutter.
  /// Restringe el rango entre "mañana" y 60 días a futuro, para evitar
  /// que el cliente agende citas en el pasado o demasiado lejos.
  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (fecha != null) setState(() => _fechaSeleccionada = fecha);
  }

  /// Abre el selector nativo de hora (reloj) de Flutter.
  /// Se inicializa en 10:00 AM como hora sugerida por defecto.
  Future<void> _seleccionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (hora != null) setState(() => _horaSeleccionada = hora);
  }

  /// Valida que se haya elegido fecha y hora, formatea ambos valores al
  /// formato que espera el backend ('YYYY-MM-DD' y 'HH:MM'), y envía la
  /// reserva mediante ApiService.crearReserva. Si todo sale bien, muestra
  /// confirmación y regresa a HomeScreen; si falla, muestra el error.
  Future<void> _confirmarReserva() async {
    if (_fechaSeleccionada == null || _horaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona fecha y hora antes de continuar.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Formatea la fecha a 'YYYY-MM-DD' rellenando con ceros a la izquierda
    // (padLeft) para que mes y día siempre tengan 2 dígitos.
    final fechaFormateada =
        '${_fechaSeleccionada!.year.toString().padLeft(4, '0')}-'
        '${_fechaSeleccionada!.month.toString().padLeft(2, '0')}-'
        '${_fechaSeleccionada!.day.toString().padLeft(2, '0')}';

    // Formatea la hora a 'HH:MM' en formato 24 horas.
    final horaFormateada =
        '${_horaSeleccionada!.hour.toString().padLeft(2, '0')}:'
        '${_horaSeleccionada!.minute.toString().padLeft(2, '0')}';

    final resultado = await ApiService.crearReserva(
      idBarbero: widget.barbero['id_usuario'],
      idServicio: widget.servicio['id_servicio'],
      fechaCita: fechaFormateada,
      horaCita: horaFormateada,
      notas: _notasController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (resultado['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Cita agendada correctamente!'),
          backgroundColor: Colors.green,
        ),
      );
      // Regresa a HomeScreen (pop simple, ya que ReservaScreen fue abierta
      // con push, no con pushReplacement).
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['message'] ?? 'No se pudo agendar la cita'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar Reserva')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta con el resumen del servicio elegido en HomeScreen.
            Card(
              child: ListTile(
                leading: const Icon(Icons.content_cut, color: Colors.indigo),
                title: Text(widget.servicio['nombre_servicio'] ?? ''),
                subtitle: Text(
                  '${widget.servicio['duracion_minutos'] ?? '30'} min · \$${widget.servicio['precio'] ?? '0.00'}',
                ),
              ),
            ),
            // Tarjeta con el resumen del barbero elegido en HomeScreen.
            Card(
              child: ListTile(
                leading: const Icon(Icons.person, color: Colors.indigo),
                title: Text(
                  'Con ${widget.barbero['nombre'] ?? ''} ${widget.barbero['apellido'] ?? ''}',
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Fila para elegir la fecha: muestra la fecha elegida o un
            // texto guía, con un botón que abre el DatePicker.
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(
                _fechaSeleccionada == null
                    ? 'Selecciona una fecha'
                    : '${_fechaSeleccionada!.day}/${_fechaSeleccionada!.month}/${_fechaSeleccionada!.year}',
              ),
              trailing: TextButton(
                onPressed: _seleccionarFecha,
                child: const Text('Elegir'),
              ),
            ),
            // Fila para elegir la hora: mismo patrón que la fecha, usando
            // TimeOfDay.format(context) para mostrarla en formato legible.
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: Text(
                _horaSeleccionada == null
                    ? 'Selecciona una hora'
                    : _horaSeleccionada!.format(context),
              ),
              trailing: TextButton(
                onPressed: _seleccionarHora,
                child: const Text('Elegir'),
              ),
            ),
            const SizedBox(height: 15),
            // Campo de texto opcional para que el cliente agregue
            // indicaciones especiales (ej. "corte con máquina 2").
            TextField(
              controller: _notasController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 25),
            // Botón final de confirmación: deshabilitado mientras se
            // procesa la petición, mostrando un spinner en su lugar.
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isLoading ? null : _confirmarReserva,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Confirmar Cita'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
