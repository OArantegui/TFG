# 🧱 BrickStock - Lego Investment Manager

**BrickStock** es una aplicación multiplataforma (móvil y web) diseñada para gestionar carteras de inversión de sets de Lego. Permite a los usuarios consultar el catálogo oficial, gestionar sus colecciones y analizar el valor de mercado de sus activos.

Este proyecto es parte del **Trabajo de Fin de Grado (TFG)** del ciclo de Desarrollo de Aplicaciones Multiplataforma (DAM) de Jhon Mario Agudelo y Óscar Arantegui.

## 🚀 Stack Tecnológico

* **Frontend:** Flutter (Dart).
* **Backend:** Node.js con Express.
* **Base de Datos:** PostgreSQL (Próximamente).
* **API Externa:** Rebrickable API v3.
* **Arquitectura:** Cliente-Servidor con patrón BFF (Backend for Frontend).

## 📂 Estructura del Proyecto

El repositorio está organizado como un monorepo:

* `/brickstock`: Código fuente de la aplicación Flutter.
* `/brickstock_backend`: API REST en Node.js que actúa como pasarela.

## 🛠️ Guía de Instalación

Para ejecutar este proyecto localmente, necesitas tener instalado:
* [Flutter SDK](https://flutter.dev/docs/get-started/install)
* [Node.js](https://nodejs.org/) (v14 o superior)

### 1. Configuración del Backend

1.  Navega a la carpeta del servidor:
    ```bash
    cd brickstock_backend
    ```
2.  Instala las dependencias:
    ```bash
    npm install
    ```
3.  **Configuración de Entorno:**
    Crea un archivo `.env` en la carpeta `brickstock_backend` basándote en el siguiente esquema:
    ```env
    PORT=3000
    REBRICKABLE_API_KEY=TU_API_KEY_AQUI
    REBRICKABLE_BASE_URL=[https://rebrickable.com/api/v3/lego](https://rebrickable.com/api/v3/lego)
    ```
4.  Arranca el servidor:
    ```bash
    npm run dev
    ```
    *El servidor correrá en `http://localhost:3000`*

### 2. Configuración de la App Móvil

1.  Navega a la carpeta de la app:
    ```bash
    cd brickstock
    ```
2.  Instala las dependencias:
    ```bash
    flutter pub get
    ```
3.  Ejecuta la aplicación (asegúrate de tener un emulador abierto o dispositivo conectado):
    ```bash
    flutter run
    ```

## 📝 Notas del Desarrollador

* Si usas el **Emulador de Android**, la app se conectará automáticamente a `10.0.2.2:3000` para hablar con el backend local.
* Si usas **Web o iOS Simulator**, se conectará a `localhost:3000`.

---
*Autores: Jhon Mario Agudelo, Óscar Arantegui*
*IES Pablo Serrano, DAM 2 - Curso 2025/2026*
