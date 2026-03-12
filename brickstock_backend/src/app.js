const express = require('express');
const cors = require('cors');
const legoRoutes = require('./routes/lego.routes');
const authRoutes = require('./routes/auth.routes'); 
const collectionRoutes = require('./routes/collection.routes');
const wishlistRoutes = require('./routes/wishlist.routes'); // Cuando la crees


const app = express();

// Middlewares
app.use(cors()); // Permite conexiones externas
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