const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    username: { type: String, required: true, unique: true },
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    wishlistBudget: { type: Number, default: 500 },
    unlockedAchievements: [{
      achievement: { type: mongoose.Schema.Types.ObjectId, ref: 'Achievement' },
      unlockedAt: { type: Date, default: Date.now }
  }]
}, {
    timestamps: true // Guarda automáticamente la fecha de creación
});
// Magia de Mongoose para simular un JOIN sin guardar el array en el User
userSchema.virtual('collections', {
  ref: 'Collection',
  localField: '_id',
  foreignField: 'userId'
});

userSchema.virtual('wishlists', {
  ref: 'Wishlist',
  localField: '_id',
  foreignField: 'userId'
});

// Para que los campos virtuales aparezcan cuando convertimos el documento a JSON para mandarlo al frontend
userSchema.set('toJSON', { virtuals: true });
userSchema.set('toObject', { virtuals: true });
module.exports = mongoose.model('User', userSchema);