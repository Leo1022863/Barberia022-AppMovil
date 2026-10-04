from flask import Blueprint, request, jsonify
from werkzeug.security import check_password_hash, generate_password_hash
from flask_jwt_extended import create_access_token
from Barberia0222.models import Usuario, Rol, db

# Definición del Blueprint para las rutas de autenticación de la API móvil
api_auth_bp = Blueprint('api_auth', __name__, url_prefix='/api/auth')

@api_auth_bp.route('/login', methods=['POST'])
def login_api():

    """
    Endpoint para autenticación de usuarios desde la app móvil (Flutter).
    Recibe email y contraseña en formato JSON, valida credenciales y 
    retorna un token JWT junto a los datos del usuario.
    """
    try:
        # 1. Obtener la estructura JSON enviada en el cuerpo de la petición HTTP
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'message': 'No se proporcionaron datos en JSON'}), 400

        # 2. Extraer el email y password del payload recibido
        email = data.get('email')
        password = data.get('password')

        # 3. Validar que ambos campos obligatorios estén presentes
        if not email or not password:
            return jsonify({'success': False, 'message': 'Faltan campos obligatorios'}), 400

        # 4. Consultar en la base de datos el usuario registrado con dicho email
        usuario = Usuario.query.filter_by(email=email).first()

        # 5. Verificar la existencia del usuario y desencriptar/comparar la contraseña
        if usuario and check_password_hash(usuario.password_hash, password):
            
            # Obtener el nombre del rol usando la relación 'rol_info' definida en el modelo
            rol_nombre = usuario.rol_info.nombre_rol if usuario.rol_info else 'Cliente'
            
            # Generar el Token JWT asociando el ID único del usuario como su identidad
            access_token = create_access_token(identity=str(usuario.id_usuario))

            # Retornar respuesta exitosa (HTTP 200) con el token y el perfil del usuario
            return jsonify({
                'success': True,
                'message': 'Autenticación exitosa',
                'access_token': access_token,
                'user': {
                    'id_usuario': usuario.id_usuario,
                    'nombre': usuario.nombre,
                    'apellido': usuario.apellido,
                    'email': usuario.email,
                    'telefono': usuario.telefono,
                    'rol': rol_nombre,
                    'foto_perfil': usuario.foto_perfil  # <-- NUEVO
                }
            }), 200

        # 6. Responder error de autenticación en caso de credenciales inválidas (HTTP 401)
        return jsonify({'success': False, 'message': 'Credenciales incorrectas'}), 401

    except Exception as e:
        # Manejo global de excepciones para evitar caídas del servidor (HTTP 500)
        return jsonify({'success': False, 'message': str(e)}), 500

#API PARA REGISTRAR USUARIOS DESDE LA APP MOVIL 
@api_auth_bp.route('/registro', methods=['POST'])
def registro_api():
    """
    Endpoint para registrar nuevos usuarios desde Flutter.

    Todo usuario nuevo se registra automáticamente
    con el rol Cliente.
    """

    try:
        data = request.get_json()

        if not data:
            return jsonify({
                'success': False,
                'message': 'No se recibieron datos'
            }), 400

        nombre = data.get('nombre')
        apellido = data.get('apellido')
        telefono = data.get('telefono')
        email = data.get('email')
        password = data.get('password')

        # Validar campos obligatorios
        if not all([nombre, apellido, telefono, email, password]):
            return jsonify({
                'success': False,
                'message': 'Todos los campos son obligatorios'
            }), 400

        # Verificar correo duplicado
        usuario_existente = Usuario.query.filter_by(
            email=email
        ).first()

        if usuario_existente:
            return jsonify({
                'success': False,
                'message': 'El correo electrónico ya está registrado'
            }), 409

        # Obtener rol Cliente
        rol_cliente = Rol.query.filter_by(
            nombre_rol='Cliente'
        ).first()

        if not rol_cliente:
            return jsonify({
                'success': False,
                'message': 'No existe el rol Cliente'
            }), 500

        # Crear usuario
        nuevo_usuario = Usuario(
            nombre=nombre,
            apellido=apellido,
            telefono=telefono,
            email=email,
            password_hash=generate_password_hash(
                password,
                method='scrypt'
            ),
            id_rol=rol_cliente.id_rol
        )

        db.session.add(nuevo_usuario)
        db.session.commit()

        return jsonify({
            'success': True,
            'message': 'Usuario registrado correctamente'
        }), 201

    except Exception as e:

        db.session.rollback()

        return jsonify({
            'success': False,
            'message': str(e)
        }), 500
