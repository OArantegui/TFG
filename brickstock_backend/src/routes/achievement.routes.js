const express = require('express');
const router = express.Router();
const achievementController = require('../controllers/achievement.controller');

const { verifyJWT } = require('../middlewares/auth.middleware');

// Rutas protegidas
router.get('/', verifyJWT, achievementController.getMyAchievements);

module.exports = router;