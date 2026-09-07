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


# ---------------------------------------------------------
# 5. GET /api/citas/mis-citas-barbero (Agenda del barbero) - Protegido por JWT
# ---------------------------------------------------------
@api_barberia_bp.route('/citas/mis-citas-barbero', methods=['GET'])
@jwt_required()
def obtener_citas_barbero():
    """Obtiene las citas asignadas al barbero autenticado, ordenadas por
    fecha y hora para que pueda ver su agenda del día/semana de forma clara."""
    try:
        current_user_id = get_jwt_identity()

        citas = Cita.query.filter_by(
            id_barbero=int(current_user_id)
        ).order_by(Cita.fecha_cita.asc(), Cita.hora_cita.asc()).all()

        agenda = [{
            'id_cita': c.id_cita,
            'fecha_cita': str(c.fecha_cita),
            'hora_cita': str(c.hora_cita),
            'estado': c.estado,
            'notas': getattr(c, 'notas', ''),
            # Aquí mostramos el CLIENTE (no el barbero), ya que quien
            # consulta esta ruta es el barbero viendo a sus clientes.
            'cliente': f"{c.cliente.nombre} {c.cliente.apellido}" if hasattr(c, 'cliente') and c.cliente else "Cliente no encontrado",
            'telefono_cliente': getattr(c.cliente, 'telefono', '') if hasattr(c, 'cliente') and c.cliente else '',
            'servicio': c.servicio.nombre_servicio if hasattr(c, 'servicio') and c.servicio else "Servicio no especificado",
            'precio': float(c.servicio.precio) if hasattr(c, 'servicio') and c.servicio and c.servicio.precio else 0.0
        } for c in citas]

        return jsonify({'success': True, 'citas': agenda}), 200
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


# ---------------------------------------------------------
# 6. PUT /api/citas/<id>/estado (Cambiar estado de una cita) - Protegido por JWT
# ---------------------------------------------------------
@api_barberia_bp.route('/citas/<int:cita_id>/estado', methods=['PUT'])
@jwt_required()
def actualizar_estado_cita_api(cita_id):
    """Permite al barbero autenticado cambiar el estado de UNA de sus
    propias citas (Pendiente -> Confirmada -> Completada, o Cancelada).
    Valida que la cita realmente pertenezca a ese barbero antes de tocarla,
    para que un barbero no pueda modificar citas de otro."""
    try:
        current_user_id = get_jwt_identity()
        data = request.get_json()
        nuevo_estado = data.get('estado')

        estados_validos = ['Pendiente', 'Confirmada', 'Completada', 'Cancelada']
        if nuevo_estado not in estados_validos:
            return jsonify({'success': False, 'message': 'Estado inválido'}), 400

        cita = Cita.query.get(cita_id)
        if not cita:
            return jsonify({'success': False, 'message': 'Cita no encontrada'}), 404

        # Seguridad: solo el barbero dueño de la cita puede modificarla.
        if cita.id_barbero != int(current_user_id):
            return jsonify({'success': False, 'message': 'No autorizado para modificar esta cita'}), 403

        cita.estado = nuevo_estado
        db.session.commit()

        return jsonify({'success': True, 'message': f'Cita actualizada a "{nuevo_estado}"'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500

# ---------------------------------------------------------
# 7. GET /api/usuarios (Listado de usuarios) - Protegido, solo Admin
# ---------------------------------------------------------
@api_barberia_bp.route('/usuarios', methods=['GET'])
@jwt_required()
def obtener_usuarios():
    """Devuelve el listado completo de usuarios con su rol actual.
    Solo accesible para quien tenga rol Administrador."""
    try:
        current_user_id = get_jwt_identity()
        usuario_actual = Usuario.query.get(int(current_user_id))

        if not usuario_actual or not usuario_actual.rol_info or usuario_actual.rol_info.nombre_rol != 'Administrador':
            return jsonify({'success': False, 'message': 'Acceso restringido a administradores'}), 403

        usuarios = Usuario.query.order_by(Usuario.nombre.asc()).all()

        listado = [{
            'id_usuario': u.id_usuario,
            'nombre': u.nombre,
            'apellido': u.apellido,
            'email': u.email,
            'telefono': u.telefono,
            'rol': u.rol_info.nombre_rol if u.rol_info else 'Sin rol'
        } for u in usuarios]

        return jsonify({'success': True, 'usuarios': listado}), 200
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


# ---------------------------------------------------------
# 8. PUT /api/usuarios/<id>/rol (Cambiar rol) - Protegido, solo Admin
# ---------------------------------------------------------
@api_barberia_bp.route('/usuarios/<int:usuario_id>/rol', methods=['PUT'])
@jwt_required()
def actualizar_rol_usuario(usuario_id):
    """Permite a un Administrador cambiar el rol de cualquier usuario.
    El nuevo rol se recibe por nombre ('Cliente'/'Barbero'/'Administrador')
    y aquí lo traducimos al id_rol correspondiente en la tabla `roles`."""
    try:
        current_user_id = get_jwt_identity()
        usuario_actual = Usuario.query.get(int(current_user_id))

        if not usuario_actual or not usuario_actual.rol_info or usuario_actual.rol_info.nombre_rol != 'Administrador':
            return jsonify({'success': False, 'message': 'Acceso restringido a administradores'}), 403

        data = request.get_json()
        nombre_rol = data.get('rol')

        nuevo_rol = Rol.query.filter_by(nombre_rol=nombre_rol).first()
        if not nuevo_rol:
            return jsonify({'success': False, 'message': f'Rol "{nombre_rol}" no existe'}), 400

        usuario_objetivo = Usuario.query.get(usuario_id)
        if not usuario_objetivo:
            return jsonify({'success': False, 'message': 'Usuario no encontrado'}), 404

        # Protección básica: evita que un admin se quite su propio rol
        # y quede sin acceso al panel por accidente.
        if usuario_objetivo.id_usuario == usuario_actual.id_usuario and nombre_rol != 'Administrador':
            return jsonify({'success': False, 'message': 'No puedes quitarte tu propio rol de Administrador'}), 400

        usuario_objetivo.id_rol = nuevo_rol.id_rol
        db.session.commit()

        return jsonify({
            'success': True,
            'message': f'Rol de {usuario_objetivo.nombre} actualizado a "{nombre_rol}"'
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500


# ---------------------------------------------------------
# 9. GET /api/citas (TODAS las citas) - Protegido, solo Admin
# ---------------------------------------------------------
@api_barberia_bp.route('/citas', methods=['GET'])
@jwt_required()
def obtener_todas_las_citas():
    """Devuelve todas las citas de la barbería (sin filtrar por cliente ni
    barbero), pensado para la vista global del panel de Administrador."""
    try:
        current_user_id = get_jwt_identity()
        usuario_actual = Usuario.query.get(int(current_user_id))

        if not usuario_actual or not usuario_actual.rol_info or usuario_actual.rol_info.nombre_rol != 'Administrador':
            return jsonify({'success': False, 'message': 'Acceso restringido a administradores'}), 403

        citas = Cita.query.order_by(Cita.fecha_cita.desc(), Cita.hora_cita.desc()).all()

        listado = [{
            'id_cita': c.id_cita,
            'fecha_cita': str(c.fecha_cita),
            'hora_cita': str(c.hora_cita),
            'estado': c.estado,
            'cliente': f"{c.cliente.nombre} {c.cliente.apellido}" if c.cliente else "Cliente no encontrado",
            'barbero': f"{c.barbero.nombre} {c.barbero.apellido}" if c.barbero else "No asignado",
            'servicio': c.servicio.nombre_servicio if hasattr(c, 'servicio') and c.servicio else "Servicio no especificado",
            'precio': float(c.servicio.precio) if hasattr(c, 'servicio') and c.servicio and c.servicio.precio else 0.0
        } for c in citas]

        return jsonify({'success': True, 'citas': listado}), 200
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500