const express = require('express');
const router = express.Router();
const wishlistController = require('../controllers/wishlist.controller');

// Importamos nuestros middlewares de seguridad
const { verifyJWT } = require('../middlewares/auth.middleware');
const { validateWishlistInput, checkValidationErrors } = require('../middlewares/validation.middleware');

// [POST] Añadir un nuevo set a la lista de deseos
// Cadena: 1. Login? -> 2. Datos válidos? -> 3. Hay errores? -> 4. Controlador
router.post('/', 
    verifyJWT, 
    validateWishlistInput, 
    checkValidationErrors, 
    wishlistController.addSetToWishlist
);

// [GET] Obtener la lista de deseos completa del usuario autenticado
// Nota TFG: El GET no recibe 'body', por tanto no necesita validar inputs, solo el Token.
router.get('/', 
    verifyJWT, 
    wishlistController.getUserWishlist
);

// [PUT] Actualizar detalles de un set deseado (requiere el ID de MongoDB en la URL)
router.put('/:id', 
    verifyJWT, 
    validateWishlistInput, 
    checkValidationErrors, 
    wishlistController.updateWishlistItem
);

// [DELETE] Eliminar un set de la lista de deseos (requiere el ID de MongoDB en la URL)
// Nota TFG: Tampoco recibe 'body', así que solo comprobamos que esté logueado.
router.delete('/:id', 
    verifyJWT, 
    wishlistController.removeSetFromWishlist
);

module.exports = router;