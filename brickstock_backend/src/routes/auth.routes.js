const express = require('express');
const router = express.Router();

const { register, login } = require('../controllers/auth.controller');

// Ruta para registrar un usuario (POST http://localhost:3000/api/auth/register)
router.post('/register', register);
router.post('/login', login);

module.exports = router;