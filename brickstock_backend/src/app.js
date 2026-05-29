const express = require('express');
const cors = require('cors');
const legoRoutes = require('./routes/lego.routes');
const authRoutes = require('./routes/auth.routes'); 
const collectionRoutes = require('./routes/collection.routes');
const wishlistRoutes = require('./routes/wishlist.routes'); // Cuando la crees
const achievementRoutes = require('./routes/achievement.routes');


const app = express();

// Permitimos localhost (para desarrollo) y  dominio de GitHub Pages (para producción)
const allowedOrigins = [
  'http://localhost:3000',
  'https://oarantegui.github.io'
];

app.use(cors({
  origin: function (origin, callback) {
    // Permitir peticiones sin origen
    if (!origin) return callback(null, true);
    //OBSOLETO
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
app.use('/api/collection', collectionRoutes);
app.use('/api/wishlist', wishlistRoutes);
// Rutas base
app.use('/api/lego', legoRoutes);
app.use('/api/auth', authRoutes); 
app.use('/api/achievements', achievementRoutes);

app.get('/', (req, res) => {
    res.send('BrickStock Backend is running correctly!');
});

module.exports = app;