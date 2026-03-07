const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    username: { type: String, required: true, unique: true },
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },

    wishlist: [{ type: String }],
    collection: [{ type: String }]
}, {
    timestamps: true // Guarda automáticamente la fecha de creación
});

module.exports = mongoose.model('User', userSchema);