const mongoose = require('mongoose');

const colectionSchema = new mongoose.Schema({ 
  // Referencia al dueño
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  // Referencia al Set en nuestra caché
  setNum: {
    type: String,
    required: true,
  },
  // Datos financieros y de inventario
  quantity: {
    type: Number,
    required: true,
    min: [1, 'No puedes tener menos de 1 set en tu colección'],
    default: 1
  },
  purchasePrice: { //Obsoleto
    type: Number,
    required: true,
    min: 0,
  },
  //Cache desnormalizado para valor de coleccion 
  marketDataCache: {
    pieces: { type: Number, default: 0 },
    year: { type: Number, default: new Date().getFullYear() },
    rrp: { type: Number, default: null },
    launchDate: { type: Date, default: null },
    exitDate: { type: Date, default: null },
    themeId: { type: Number, default: null },
    rootThemeId: { type: Number, default: null }
  }
}, { 
  timestamps: true // Añade createdAt y updatedAt automáticamente
});

module.exports = mongoose.model('Collection', colectionSchema);