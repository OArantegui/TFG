const express = require('express');
const router = express.Router();

const { register, login, updateUser, refreshToken, logout, verifyCurrentPassword, updateAvatar } = require('../controllers/auth.controller');

const { verifyJWT } = require('../middlewares/auth.middleware');

// Ruta para registrar un usuario (POST http://localhost:3000/api/auth/register)
router.post('/register', register);
router.post('/login', login);
router.post('/refresh', refreshToken);
router.post('/logout', logout);

router.put('/profile', verifyJWT, updateUser);
router.post('/verify-password', verifyJWT, verifyCurrentPassword);
router.put('/avatar', verifyJWT, updateAvatar);

module.exports = router;