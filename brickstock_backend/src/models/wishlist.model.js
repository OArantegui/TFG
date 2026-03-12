const mongoose = require('mongoose');

const wishlistSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  setNum: {
    type: String,
    required: true
  },
  // Precio objetivo: Para mandarle un aviso push/email si el set baja de este precio (Feature pro para el TFG)
  targetPrice: {
    type: Number,
    min: 0
  },
  priority: {
    type: String,
    enum: ['Low', 'Medium', 'High'],
    default: 'Medium'
  }
}, { 
  timestamps: true 
});

// Un usuario no debería tener el mismo set dos veces en su lista de deseos
wishlistSchema.index({ userId: 1, setNum: 1 }, { unique: true });

module.exports = mongoose.model('Wishlist', wishlistSchema);