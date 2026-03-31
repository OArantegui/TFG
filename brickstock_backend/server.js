require('dotenv').config();
const { seedAchievements } = require('./src/services/achievement.service');
const app = require('./src/app');
const mongoose = require('mongoose');

const PORT = process.env.PORT || 3000;

// Conexión a MongoDB
mongoose.connect(process.env.MONGODB_URI)
  .then(() => {
    console.log('Conectado a MongoDB Atlas con éxito');
    seedAchievements();})
  .catch((error) => console.error('Error al conectar a MongoDB:', error));

app.listen(PORT, () => {
    console.log(`Servidor BrickStock corriendo en el puerto ${PORT}`);
});