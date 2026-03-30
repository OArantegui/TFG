const express = require('express');
const router = express.Router();

const { register, login, updateUser } = require('../controllers/auth.controller');

const authMiddleware = require('../middlewares/auth.middleware');

// Ruta para registrar un usuario (POST http://localhost:3000/api/auth/register)
router.post('/register', register);
router.post('/login', login);

router.put('/profile', authMiddleware, updateUser);

module.exports = router;