const mongoose = require('mongoose');

const achievementSchema = new mongoose.Schema({
  code: { type: String, required: true, unique: true }, // ej: 'FIRST_SET'
  name: { type: String, required: true }, // ej: 'Primer Ladrillo'
  description: { type: String, required: true },
  icon: { type: String, required: true }, // Guardaremos el nombre del icono de Material de Flutter
  conditionType: { type: String, required: true }, // ej: 'COLLECTION_COUNT'
  conditionValue: { type: Number, required: true }, // ej: 1 (set)
});

module.exports = mongoose.model('Achievement', achievementSchema);