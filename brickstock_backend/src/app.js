const express = require('express');
const cors = require('cors');
const legoRoutes = require('./routes/lego.routes');
const authRoutes = require('./routes/auth.routes'); 
const collectionRoutes = require('./routes/collection.routes');
const wishlistRoutes = require('./routes/wishlist.routes'); // Cuando la crees


const app = express();

// === CONFIGURACIÓN CORS ACTUALIZADA ===
// Permitimos localhost (para desarrollo) y tu dominio de GitHub Pages (para producción)
const allowedOrigins = [
  'http://localhost:3000',
  'https://oarantegui.github.io' // ¡Pon aquí la URL base de tu frontend sin la barra final!
];

app.use(cors({
  origin: function (origin, callback) {
    // Permitir peticiones sin origen (como Postman o llamadas móviles directas)
    if (!origin) return callback(null, true);
    // BORRAR EN SU MOMENTO
    // 2. Permitir cualquier petición desde localhost, 127.0.0.1 o el emulador de Android (10.0.2.2)
    if (origin.startsWith('http://localhost') || 
        origin.startsWith('http://127.0.0.1') || 
        origin.startsWith('http://10.0.2.2')) {
      return callback(null, true);
    }
    
    if (allowedOrigins.indexOf(origin) === -1) {
      var msg = 'La política CORS para este sitio no permite el acceso desde el Origen especificado.';
      return callback(new Error(msg), false);
    }
    return callback(null, true);
  },
  credentials: true
}));
app.use(express.json()); // Permite recibir JSON
// Montar las rutas en un prefijo base
app.use('/api/collection', collectionRoutes);
app.use('/api/wishlist', wishlistRoutes);
// Rutas base
app.use('/api/lego', legoRoutes);
app.use('/api/auth', authRoutes); 

// Ruta de salud (Health Check)
app.get('/', (req, res) => {
    res.send('BrickStock Backend is running correctly!');
});

module.exports = app;