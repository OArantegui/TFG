const User = require('../models/user.model');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const register = async (req, res) => {
    try {
        const { username, email, password } = req.body;

        // 1. Comprobar si el usuario ya existe
        const userExists = await User.findOne({ email });
        if (userExists) {
            return res.status(400).json({ message: 'El correo ya está en uso' });
        }

        // 2. Encriptar la contraseña
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        // 3. Crear el nuevo usuario
        const newUser = new User({
            username,
            email,
            password: hashedPassword
        });

        // 4. Guardarlo en MongoDB Atlas
        await newUser.save();

        // 5. Crear el token de sesión (JWT)
        const token = jwt.sign(
            { id: newUser._id }, 
            process.env.JWT_SECRET, 
            { expiresIn: '30d' } // El token durará 30 días
        );

        // 6. Enviar respuesta de éxito al móvil
        res.status(201).json({
            message: 'Usuario creado con éxito',
            token: token,
            user: {
                id: newUser._id,
                username: newUser.username,
                email: newUser.email
            }
        });

    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error en el servidor al registrar usuario' });
    }
};

module.exports = { register };