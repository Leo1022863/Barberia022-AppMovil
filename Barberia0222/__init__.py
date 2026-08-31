import os
from flask import Flask, flash, redirect, render_template, request, url_for
from config import Config
from Barberia0222.models import db, Usuario
from flask_login import LoginManager
#Importación de extensiones necesarias para soporte móvil - para la API Móvil
from flask_cors import CORS
from flask_jwt_extended import JWTManager

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    # Configuración de la clave secreta para la firma de tokens JWT
    app.config['SECRET_KEY'] = 'tu_clave_secreta_aqui'
    app.config['JWT_SECRET_KEY'] = app.config.get('SECRET_KEY', 'clave_secreta_super_segura_de_mas_de_32_caracteres_12345')

    # Inicializar la base de datos
    db.init_app(app)
    
    # Habilita CORS para permitir peticiones HTTP desde aplicaciones móviles/Flutter
    CORS(app)
    
    # Inicialización del gestor de tokens JWT
    jwt = JWTManager(app)
    
    # Configuración de Flask-Login (Mantenido intacto para la versión Web)
    login_manager = LoginManager()
    login_manager.login_view = 'auth.login'
    login_manager.login_message = "Por favor inicia sesión para acceder."
    login_manager.init_app(app)

    @login_manager.user_loader
    def load_user(user_id):
        return Usuario.query.get(int(user_id))

    # --- RUTAS PRINCIPALES ---
    
    @app.route('/')
    def index():
        return render_template('index.html')

    @app.route('/contacto', methods=['POST'])
    def contacto():
        nombre = request.form.get('nombre')
        email = request.form.get('email')
        mensaje = request.form.get('mensaje')
        flash('¡Gracias por escribirnos! Te responderemos pronto.', 'success')
        return redirect(url_for('index') + '#contacto')

    # --- REGISTRO DE BLUEPRINTS ---
    
    # 1. Blueprint para la interfaz Web (Plantillas HTML / Flask-Login)
    from Barberia0222.routes.auth import auth_bp
    app.register_blueprint(auth_bp, url_prefix='/auth')

    # 2. Blueprint para la API Móvil (Respuestas JSON / JWT)
    from Barberia0222.routes.api_auth import api_auth_bp
    app.register_blueprint(api_auth_bp)

    # --- 2. REGISTRO DE BLUEPRINTS  ---
   # [NUEVO] Registrar Blueprint de datos de barbería
    from Barberia0222.routes.api_barberia import api_barberia_bp
    app.register_blueprint(api_barberia_bp)

    return app