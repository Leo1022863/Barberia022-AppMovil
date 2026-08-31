from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from Barberia0222.models import Usuario, Rol, Servicio, Cita, db

# Blueprint para la gestión de servicios, barberos y citas en la API
api_barberia_bp = Blueprint('api_barberia', __name__, url_prefix='/api')

# ---------------------------------------------------------
# 1. GET /api/servicios (Lista de servicios disponibles)
# ---------------------------------------------------------
@api_barberia_bp.route('/servicios', methods=['GET'])
def get_servicios():
    """Retorna la lista completa de servicios registrados en la barbería."""
    try:
        servicios = Servicio.query.all()
        lista_servicios = [{
            'id_servicio': s.id_servicio,
            'nombre_servicio': s.nombre_servicio,
            'descripcion': s.descripcion,
            'duracion_minutos': s.duracion_minutos,
            'precio': float(s.precio) if s.precio else 0.0,
            'estado': s.estado
        } for s in servicios]
        
        return jsonify({'success': True, 'servicios': lista_servicios}), 200
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

# ---------------------------------------------------------
# 2. GET /api/barberos (Lista de barberos disponibles)
# ---------------------------------------------------------
@api_barberia_bp.route('/barberos', methods=['GET'])
def get_barberos():
    """Retorna la lista de usuarios que tienen el rol de 'Barbero'."""
    try:
        barberos = Usuario.query.join(Rol).filter(Rol.nombre_rol.ilike('barbero')).all()
        lista_barberos = [{
            'id_usuario': b.id_usuario,
            'nombre': b.nombre,
            'apellido': b.apellido,
            'email': b.email,
            'telefono': b.telefono
        } for b in barberos]
        
        return jsonify({'success': True, 'barberos': lista_barberos}), 200
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

# ---------------------------------------------------------
# 3. POST /api/citas (Creación de reservas) - Protegido por JWT
# ---------------------------------------------------------
@api_barberia_bp.route('/citas', methods=['POST'])
@jwt_required()
def agendar_cita():
    """Registra una nueva cita asociada al cliente autenticado mediante JWT."""
    try:
        current_user_id = get_jwt_identity()
        data = request.get_json()

        id_barbero = data.get('id_barbero')
        id_servicio = data.get('id_servicio')
        fecha_cita = data.get('fecha_cita') or data.get('fecha')  # Formato YYYY-MM-DD
        hora_cita = data.get('hora_cita') or data.get('hora')     # Formato HH:MM
        notas = data.get('notas', '')

        if not all([id_barbero, id_servicio, fecha_cita, hora_cita]):
            return jsonify({'success': False, 'message': 'Faltan campos obligatorios'}), 400

        nueva_cita = Cita(
            id_cliente=current_user_id,
            id_barbero=id_barbero,
            id_servicio=id_servicio,
            fecha_cita=fecha_cita,
            hora_cita=hora_cita,
            estado='Pendiente',
            notas=notas
        )

        db.session.add(nueva_cita)
        db.session.commit()

        return jsonify({'success': True, 'message': 'Cita agendada correctamente'}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500

# ---------------------------------------------------------
# 4. GET /api/citas/mis-citas (Historial de citas del cliente) - Protegido por JWT
# ---------------------------------------------------------
@api_barberia_bp.route('/citas/mis-citas', methods=['GET'])
@jwt_required()
def obtener_mis_citas():
    """Obtiene el historial de citas agendadas únicamente por el cliente logueado."""
    try:
        current_user_id = get_jwt_identity()
        
        citas = Cita.query.filter_by(id_cliente=current_user_id).all()
        
        historial = [{
            'id_cita': c.id_cita,
            'fecha_cita': str(c.fecha_cita),
            'hora_cita': str(c.hora_cita),
            'estado': c.estado,
            'notas': getattr(c, 'notas', ''),
            'barbero': f"{c.barbero.nombre} {c.barbero.apellido}" if hasattr(c, 'barbero') and c.barbero else "No asignado",
            'servicio': c.servicio.nombre_servicio if hasattr(c, 'servicio') and c.servicio else "Servicio no especificado",
            'precio': float(c.servicio.precio) if hasattr(c, 'servicio') and c.servicio and c.servicio.precio else 0.0
        } for c in citas]

        return jsonify({'success': True, 'citas': historial}), 200
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500