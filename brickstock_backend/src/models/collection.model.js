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
  purchasePrice: { //Revisar esto
    type: Number,
    required: true,
    min: 0,
  },
  condition: { //Revisar esto
    type: String,
    enum: ['NISB', 'Used', 'Incomplete'],
    default: 'NISB'
  },
  purchaseDate: { //Revisar esto
    type: Date,
    default: Date.now
  },
  // Por si en el futuro queremos registrar ventas
  status: {
    type: String,
    enum: ['Holding', 'Sold'], // Holding = Lo mantengo en cartera
    default: 'Holding'
  },
  //Cache desnormalizado para valor de coleccion 
  marketDataCache: {
    pieces: { type: Number, default: 0 },
    year: { type: Number, default: new Date().getFullYear() },
    rrp: { type: Number, default: null },
    launchDate: { type: Date, default: null },
    exitDate: { type: Date, default: null }
  }
}, { 
  timestamps: true // Añade createdAt y updatedAt automáticamente
});

// Índice compuesto opcional: Evita que un usuario añada exactamente el mismo set con el mismo estado sin agruparlo
// portfolioSchema.index({ userId: 1, setNum: 1, condition: 1 }, { unique: true });

module.exports = mongoose.model('Collection', colectionSchema);