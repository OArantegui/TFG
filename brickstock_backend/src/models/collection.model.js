const mongoose = require('mongoose');

const colectionSchema = new mongoose.Schema({
  // Referencia al dueño de este registro
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true // ¡Vital para el rendimiento! Acelera la búsqueda "find({ userId: X })"
  },
  // Referencia al Set en nuestra caché (el set_num de Rebrickable, ej: "42115-1")
  setNum: {
    type: String,
    required: true,
    // Nota: Podríamos hacer un ref: 'SetCache' si luego queremos hacer .populate() de los datos del set
  },
  // Datos financieros y de inventario
  quantity: {
    type: Number,
    required: true,
    min: [1, 'No puedes tener menos de 1 set en tu colección'],
    default: 1
  },
  purchasePrice: {
    type: Number,
    required: true,
    min: 0,
    // Comentario TFG: Guardamos el precio total pagado por unidad. Fundamental para el cálculo del ROI.
  },
  condition: {
    type: String,
    enum: ['NISB', 'Used', 'Incomplete'], // NISB = New In Sealed Box (Nuevo Sellado)
    default: 'NISB'
  },
  purchaseDate: {
    type: Date,
    default: Date.now
  },
  // Por si en el futuro queremos registrar ventas
  status: {
    type: String,
    enum: ['Holding', 'Sold'], // Holding = Lo mantengo en cartera
    default: 'Holding'
  }
}, { 
  timestamps: true // Añade createdAt y updatedAt automáticamente
});

// Índice compuesto opcional: Evita que un usuario añada exactamente el mismo set con el mismo estado sin agruparlo
// portfolioSchema.index({ userId: 1, setNum: 1, condition: 1 }, { unique: true });

module.exports = mongoose.model('Collection', colectionSchema);