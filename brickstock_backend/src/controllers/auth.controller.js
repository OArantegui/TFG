const User = require('../models/user.model');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const register = async (req, res) => {
    try {
        const { username, email, password } = req.body;
        console.log(`Registro -> User: ${username}, Email: ${email}`);

        // 1. Comprobar si el correo O el username ya existen
        const userExists = await User.findOne({ $or: [{ email }, { username }] });
        if (userExists) {
            return res.status(400).json({ message: 'El correo o el nombre de usuario ya están en uso' });
        }

        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        const newUser = new User({
            username,
            email,
            password: hashedPassword
        });

        await newUser.save();
        
        const token = jwt.sign(
            { id: newUser._id }, 
            process.env.JWT_SECRET, 
            { expiresIn: '30d' } 
        );

        res.status(201).json({
            message: 'Usuario creado con éxito',
            token: token,
            user: { id: newUser._id, username: newUser.username, email: newUser.email }
        });

    } catch (error) {
        console.error("ERROR EN REGISTRO:", error);
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
                username: user.username,
                email: user.email
            }
        });

    } catch (error) {
        console.error("🔥 ERROR GRAVE EN LOGIN:", error);
        res.status(500).json({ message: 'Error en el servidor al iniciar sesión' });
    }
};

//Metodo para actualizar usuario desde ajustes
const updateUser = async (req, res) => {
    try {
        const { username, email, password } = req.body;
        // Obtenemos el ID del token JWT (asumiendo que usas tu auth.middleware.js en la ruta)
        const userId = req.user.id; 

        let updateFields = {};

        // Validar unicidad si cambian username o email
        if (username || email) {
            const query = [];
            if (username) query.push({ username });
            if (email) query.push({ email });
            
            const existingUser = await User.findOne({ 
                $or: query, 
                _id: { $ne: userId } // Que no sea el propio usuario
            });

            if (existingUser) {
                return res.status(400).json({ message: 'El correo o username ya están en uso por otra persona' });
            }
            if (username) updateFields.username = username;
            if (email) updateFields.email = email;
        }

        if (password) {
            const salt = await bcrypt.genSalt(10);
            updateFields.password = await bcrypt.hash(password, salt);
        }

        const updatedUser = await User.findByIdAndUpdate(userId, updateFields, { new: true });

        res.status(200).json({
            message: 'Perfil actualizado',
            user: { username: updatedUser.username, email: updatedUser.email }
        });

    } catch (error) {
        res.status(500).json({ message: 'Error actualizando el perfil' });
    }
};

module.exports = { register, login, updateUser };