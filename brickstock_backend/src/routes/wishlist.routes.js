const express = require('express');
const router = express.Router();
const wishlistController = require('../controllers/wishlist.controller');
const { verifyJWT } = require('../middlewares/auth.middleware');

router.use(verifyJWT);

router.post('/', wishlistController.addToWishlist);
router.get('/', wishlistController.getUserWishlist);
router.delete('/:id', wishlistController.deleteFromWishlist);
router.put('/budget', wishlistController.updateBudget);

module.exports = router;