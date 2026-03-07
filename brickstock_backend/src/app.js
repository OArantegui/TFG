const express = require('express');
const cors = require('cors');
const legoRoutes = require('./routes/lego.routes');
const authRoutes = require('./routes/auth.routes'); 

const app = express();

// Middlewares
app.use(cors()); // Permite conexiones externas
app.use(express.json()); // Permite recibir JSON

// Rutas base
app.use('/api/lego', legoRoutes);
app.use('/api/auth', authRoutes); 

// Ruta de salud (Health Check)
app.get('/', (req, res) => {
    res.send('BrickStock Backend is running correctly!');
});

module.exports = app;