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
  targetPrice: {
    type: Number,
    min: 0
  }
}, { 
  timestamps: true 
});

// Un usuario no debería tener el mismo set dos veces en su lista de deseos
wishlistSchema.index({ userId: 1, setNum: 1 }, { unique: true });

module.exports = mongoose.model('Wishlist', wishlistSchema);