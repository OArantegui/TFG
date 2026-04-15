const mongoose = require('mongoose');

const achievementSchema = new mongoose.Schema({
  code: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  description: { type: String, required: true },
  icon: { type: String, required: true },
  conditionType: { type: String, required: true },
  conditionValue: { type: Number, required: true },
});

module.exports = mongoose.model('Achievement', achievementSchema);