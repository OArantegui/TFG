const User = require('../models/user.model');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const register = async (req, res) => {
    try {
        //const { username, email, password } = req.body; Quitamos el username para que coincida con el front. Igual hay que volver a añadirlo más tarde para poder registrarse con usuario
        const { email, password } = req.body;
        console.log(`Datos recibidos -> Email: ${email}, Password: ${password}`);

        // 1. Comprobar si el usuario ya existe
        const userExists = await User.findOne({ email });
        if (userExists) {
            console.log("❌ Rechazado: El correo ya existe en la BBDD.");
            return res.status(400).json({ message: 'El correo ya está en uso' });
        }

        // 2. Encriptar la contraseña
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        // 3. Crear el nuevo usuario
        const newUser = new User({
            //username,
            email,
            password: hashedPassword
        });

        // 4. Guardarlo en MongoDB Atlas
        await newUser.save();
        console.log("✅ Éxito: Usuario guardado en MongoDB con ID:", newUser._id);

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
                //username: newUser.username, Lo mismo que arriba, quitamos el username
                email: newUser.email
            }
        });

    } catch (error) {
        console.error("🔥 ERROR GRAVE EN REGISTRO:", error);
        res.status(500).json({ message: 'Error en el servidor al registrar usuario' });
    }
};

const login = async (req, res) => {
    try {
        const { email, password } = req.body;
        console.log(`Datos recibidos -> Email: ${email}, Password: ${password}`);

        // 1. Buscar si existe un usuario con ese email
        const user = await User.findOne({ email });
        if (!user) {
            console.log("❌ Rechazado: No se encontró el usuario en la BBDD.");
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        // 2. Comprobar si la contraseña es correcta (bcrypt compara la normal con la encriptada)
        const isPasswordCorrect = await bcrypt.compare(password, user.password);
        if (!isPasswordCorrect) {
            console.log("❌ Rechazado: La contraseña no coincide con el hash.");
            return res.status(400).json({ message: 'Contraseña incorrecta' });
        }

        console.log("✅ Éxito: Contraseña correcta. Generando token...");

        // 3. Si todo está bien, crear el pase VIP (Token JWT)
        const token = jwt.sign(
            { id: user._id }, 
            process.env.JWT_SECRET, 
            { expiresIn: '30d' }
        );

        // 4. Enviar los datos al móvil
        res.status(200).json({
            message: 'Login exitoso',
            token: token,
            user: {
                id: user._id,
                //username: user.username,
                email: user.email
            }
        });

    } catch (error) {
        console.error("🔥 ERROR GRAVE EN LOGIN:", error);
        res.status(500).json({ message: 'Error en el servidor al iniciar sesión' });
    }
};

module.exports = { register, login };