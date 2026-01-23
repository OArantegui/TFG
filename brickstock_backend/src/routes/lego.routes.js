const express = require('express');
const router = express.Router();
const legoController = require('../controllers/lego.controller');

// Definimos las rutas: http://localhost:3000/api/lego/...
router.get('/themes', legoController.getThemes);
router.get('/sets/:themeId', legoController.getSets);

module.exports = router;