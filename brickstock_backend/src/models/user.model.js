const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    username: { type: String, required: true, unique: true },
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    wishlistBudget: { type: Number, default: 500 },
    refreshTokens: [{ type: String }],
    unlockedAchievements: [{
      achievement: { type: mongoose.Schema.Types.ObjectId, ref: 'Achievement' },
      unlockedAt: { type: Date, default: Date.now }
    }],
    avatar: {
      type: String,
      default: 'assets/avatars/lego-default.jpg' // Avatar por defecto
    }
}, {
    timestamps: true // Guarda automáticamente la fecha de creación
});

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

userSchema.set('toJSON', { virtuals: true });
userSchema.set('toObject', { virtuals: true });
module.exports = mongoose.model('User', userSchema);