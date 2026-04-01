const mongoose = require('mongoose');

const minifigCollectionSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true 
  },
  figNum: {
    type: String,
    required: true,
  },
  quantity: {
    type: Number,
    required: true,
    min: 1,
    default: 1
  },
  // Indicamos si la minifigura se obtuvo al comprar un Set o se añadió manualmente suelta
  source: {
    type: String,
    enum: ['From Set', 'Manual'],
    default: 'Manual'
  },
  // Si viene de un set, guardamos de qué set vino (opcional, pero genial para trazabilidad)
  sourceSetNum: {
    type: String,
    default: null
  }
}, { 
  timestamps: true 
});

module.exports = mongoose.model('MinifigCollection', minifigCollectionSchema);