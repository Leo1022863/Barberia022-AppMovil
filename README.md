# Barberia022-AppMovil

# Barbería022-AppMovil

Aplicación móvil multiplataforma desarrollada en Flutter para la gestión integral de citas de una barbería. El sistema permite a clientes, barberos y administradores interactuar mediante una interfaz móvil conectada a un backend desarrollado en Flask y una base de datos MySQL.

---

# Descripción del Proyecto

Barbería022-AppMovil surge como una solución tecnológica para digitalizar el proceso de reservas y administración de una barbería, permitiendo gestionar citas, usuarios y servicios desde dispositivos móviles.

La aplicación implementa autenticación mediante JWT, gestión de roles, almacenamiento local para persistencia de sesión y funcionalidades nativas del dispositivo como cámara, galería y notificaciones locales.

---

# Objetivo

Desarrollar una aplicación móvil que permita:

- Gestionar reservas de citas.
- Administrar usuarios y roles.
- Consultar servicios disponibles.
- Gestionar la agenda de los barberos.
- Mejorar la experiencia del cliente mediante notificaciones y personalización del perfil.

---

# Roles del Sistema

## Cliente

- Registro de cuenta.
- Inicio de sesión.
- Cambio de foto de perfil.
- Consulta de servicios.
- Consulta de barberos.
- Reserva de citas.
- Consulta del historial de citas.
- Recepción de notificaciones locales.

## Barbero

- Inicio de sesión.
- Consulta de agenda.
- Visualización de citas asignadas.
- Cambio de estado de citas:
  - Pendiente
  - Confirmada
  - Completada
  - Cancelada

## Administrador

- Gestión de usuarios.
- Consulta de usuarios registrados.
- Asignación de roles.
- Consulta global de citas.

---

# Tecnologías Utilizadas

## Frontend

- Flutter
- Dart
- Material Design

## Backend

- Flask
- Flask JWT Extended
- Flask SQLAlchemy
- Flask CORS

## Base de Datos

- MySQL

## Funcionalidades Nativas

- image_picker
- permission_handler
- flutter_local_notifications

## Persistencia Local

- SharedPreferences

---

# Funcionalidades Implementadas

## Autenticación

- Login con JWT.
- Registro de usuarios.
- Persistencia de sesión.
- Splash Screen.
- Navegación según rol.

## Gestión de Citas

- Creación de reservas.
- Listado de citas del cliente.
- Agenda del barbero.
- Cambios de estado.
- Consulta global de citas.

## Gestión de Usuarios

- Listado de usuarios.
- Actualización de roles.
- Control de acceso según privilegios.

## Perfil de Usuario

- Captura de fotografía desde cámara.
- Selección desde galería.
- Almacenamiento en servidor.
- Persistencia de fotografía.

## Notificaciones

- Solicitud de permisos.
- Notificaciones locales.
- Confirmación automática al registrar una cita.

---

# Arquitectura General

```text
Flutter Mobile App
        │
        ▼
     API REST
        │
        ▼
 Flask Backend
        │
        ▼
     MySQL
