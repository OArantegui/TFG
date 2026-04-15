const express = require('express');
const router = express.Router();
const legoController = require('../controllers/lego.controller');

// Definimos las rutas
router.get('/themes', legoController.getThemes);
router.get('/themes/:themeId/cover', legoController.getThemeCover);
router.get('/sets/:themeId', legoController.getSetsByTheme);
router.get('/image-proxy', legoController.getImageProxy);
router.get('/sets/:set_num/minifigs', legoController.getSetMinifigs);
router.get('/minifigs/:fig_num/sets', legoController.getMinifigSets);
router.get('/sets', legoController.getAllSets);
router.get('/minifigs', legoController.getMinifigs);
router.get('/minifigs/:figNum', legoController.getMinifigDetails);
router.get('/themes/:id', legoController.getThemeById);

router.get('/sets/:setId/market-data', legoController.getSetMarketData);

router.get('/scan/:barcode', legoController.scanBarcode);
router.get('/sets/:setId/instructions', legoController.getSetInstructions);

module.exports = router;