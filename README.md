# 🧱 BrickStock

![Flutter](https://img.shields.io/badge/Frontend-Flutter-02569B?logo=flutter)
![Node.js](https://img.shields.io/badge/Backend-Node.js-339933?logo=node.js)
![MongoDB](https://img.shields.io/badge/Database-MongoDB-47A248?logo=mongodb)
![Status](https://img.shields.io/badge/Status-En%20Desarrollo-orange)

**BrickStock** es un gestor financiero y *broker* de colecciones de LEGO. Diseñado para unificar el fragmentado mercado de datos de LEGO, permite a los coleccionistas gestionar su inventario, escanear nuevos sets y trackear el valor financiero de su colección en tiempo real mediante una interfaz nativa y amigable.

---

## ✨ Características Principales

* 📸 **Escáner Inteligente:** Identifica sets de LEGO escaneando el código de barras (EAN/UPC) con la cámara del dispositivo.
* 📈 **Análisis de Mercado:** Gráficas históricas de precios y cálculo del valor actual de la colección combinando datos de múltiples fuentes.
* 🗂️ **Gestión de Colección y Wishlist:** Añade, edita y organiza tus sets y minifiguras.
* 🏆 **Gamificación:** Sistema de logros automáticos según los hitos alcanzados en la colección del usuario.
* 🔒 **Seguridad Avanzada:** Sistema de autenticación robusto sin fricción para el usuario.
* 📱 **Multiplataforma:** Código base único en Flutter preparado para iOS, Android y Web.

---

## 🏗️ Arquitectura y Decisiones Técnicas

Este proyecto está construido bajo el patrón **BFF (Backend For Frontend)**. Node.js se encarga de orquestar múltiples APIs externas, aplicar lógica de negocio y servir los datos listos para ser consumidos por el cliente en Flutter.

### 🧠 Sistema de Caché Dual (Escalabilidad)
Para evitar los *Rate Limits* de las APIs externas y reducir drásticamente los tiempos de carga, BrickStock implementa dos capas de caché:
1. **Caché en Memoria (RAM - 5 mins):** Para consultas de búsqueda dinámicas y catálogos, evitando llamadas duplicadas inmediatas.
2. **Caché Persistente en BBDD (MongoDB - 30 días):** Almacena los datos financieros de un set (mediante operaciones `Upsert`) durante un mes. Si el dato es solicitado nuevamente dentro de ese periodo, se sirve en milisegundos sin consumir cuota de red.

### 🗄️ Modelado de Datos NoSQL
En lugar de embutir enormes documentos JSON por cada set que un usuario añade a su colección, utilizamos **Referencias Ligeras**. La base de datos solo guarda la relación `(userId, setId, precioTransaccional)`. El backend "rehidrata" los datos visuales al vuelo, manteniendo la base de datos ágil y evitando la duplicación masiva de imágenes y descripciones.

### 🛡️ Seguridad y Sesiones
* **Contraseñas:** Cifrado unidireccional con *Salting* mediante `bcrypt`.
* **JSON Web Tokens (JWT):** Arquitectura de doble token para máxima seguridad UX. Un `Access Token` de vida corta (15 min) protege las rutas HTTP de Express, mientras que un `Refresh Token` de vida larga (30 días) alojado en el almacenamiento encriptado del dispositivo móvil renueva la sesión silenciosamente por debajo.

---

## 💻 Stack Tecnológico

### Frontend (Mobile & Web)
* **Framework:** Flutter / Dart
* **Gestor de Estado:** Provider
* **Almacenamiento Local:** `flutter_secure_storage`, `shared_preferences`
* **Librerías Clave:** `http` (Networking), `fl_chart` (Gráficas), `mobile_scanner` (Lector de códigos de barras).

### Backend (API REST)
* **Entorno:** Node.js con Express.js
* **Base de Datos:** MongoDB Atlas + Mongoose
* **Seguridad:** `jsonwebtoken`, `bcryptjs`
* **APIs Externas Integradas:** [Rebrickable API](https://rebrickable.com/api/) (Datos visuales y catálogo) y [Brickset API](https://brickset.com/tools/webservices) (Datos financieros).

---

## 🚀 Instalación y Despliegue Local

### Requisitos Previos
* [Flutter SDK](https://flutter.dev/docs/get-started/install) (versión 3.x o superior)
* [Node.js](https://nodejs.org/) (versión 18.x o superior)
* Una cuenta en MongoDB Atlas o un servidor MongoDB local.
* Claves de API de Rebrickable y Brickset.

### Configuración del Backend
1. Navega a la carpeta del servidor: `cd backend` *(Ajustar según estructura de carpetas)*
2. Instala las dependencias: `npm install`
3. Crea un archivo `.env` en la raíz del backend con las siguientes variables:
   ```env
   PORT=3000
   MONGODB_URI=tu_cadena_de_conexion_mongo
   JWT_SECRET=tu_secreto_para_access_token
   JWT_REFRESH_SECRET=tu_secreto_para_refresh_token
   REBRICKABLE_API_KEY=tu_clave_api
   BRICKSET_API_KEY=tu_clave_api
