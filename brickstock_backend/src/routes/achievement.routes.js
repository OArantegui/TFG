const express = require('express');
const router = express.Router();
const achievementController = require('../controllers/achievement.controller');
const authMiddleware = require('../middlewares/auth.middleware');

// Rutas protegidas
router.get('/', authMiddleware.verifyToken, achievementController.getMyAchievements);

module.exports = router;