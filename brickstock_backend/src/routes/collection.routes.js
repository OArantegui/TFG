const express = require('express');
const router = express.Router();
const collectionController = require('../controllers/collection.controller');

// Middlewares de seguridad
const { verifyJWT } = require('../middlewares/auth.middleware');
const { validateCollectionInput, checkValidationErrors } = require('../middlewares/validation.middleware');

// POST Añadir a la Colección (Una sola vez y con todos los escudos)
router.post('/', 
    verifyJWT, 
    validateCollectionInput, 
    checkValidationErrors, 
    collectionController.addSetToCollection
);

// GET Ver colección
router.get('/', verifyJWT, collectionController.getUserCollection);

router.get('/market-data', verifyJWT, collectionController.getCollectionMarketData);

// PUT Modificar set en la colección
router.put('/:id', 
    verifyJWT, 
    validateCollectionInput, 
    checkValidationErrors, 
    collectionController.updateCollectionItem
);

// DELETE Borrar set de la colección
router.delete('/:id', verifyJWT, collectionController.deleteCollectionItem);

router.get('/minifigs', verifyJWT, collectionController.getUserMinifigCollection);
router.post('/minifigs', verifyJWT, collectionController.addMinifigToCollection);
router.delete('/minifigs/:id', verifyJWT, collectionController.removeMinifigFromCollection);

module.exports = router;