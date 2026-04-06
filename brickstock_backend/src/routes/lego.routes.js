const express = require('express');
const router = express.Router();
const legoController = require('../controllers/lego.controller');

// Definimos las rutas: http://localhost:3000/api/lego/...
router.get('/themes', legoController.getThemes);
router.get('/themes/:themeId/cover', legoController.getThemeCover);
router.get('/sets/:themeId', legoController.getSetsByTheme);
router.get('/image-proxy', legoController.getImageProxy);
router.get('/sets/:set_num/minifigs', legoController.getSetMinifigs);
router.get('/minifigs/:fig_num/sets', legoController.getMinifigSets);
router.get('/sets', legoController.getAllSets);
router.get('/minifigs', legoController.getMinifigs);
router.get('/minifigs/:figNum', legoController.getMinifigDetails);

router.get('/sets/:setId/market-data', legoController.getSetMarketData);

module.exports = router;