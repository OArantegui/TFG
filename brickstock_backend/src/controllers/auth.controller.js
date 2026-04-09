const User = require('../models/user.model');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const generateAccessToken = (userId) => {
    // 15 minutos de vida. Minimiza el riesgo si nos roban este token.
    return jwt.sign({ id: userId }, process.env.JWT_SECRET, { expiresIn: '15m' });
};

const generateRefreshToken = (userId) => {
    // 30 días de vida. Solo sirve para pedir un nuevo Access Token.
    return jwt.sign({ id: userId }, process.env.JWT_REFRESH_SECRET, { expiresIn: '30d' });
};

const register = async (req, res) => {
    try {
        const { username, email, password, avatar } = req.body;

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
            password: hashedPassword,
            avatar: avatar
        });

        //Generamos tokens
        const accessToken = generateAccessToken(newUser._id);
        const refreshToken = generateRefreshToken(newUser._id);

        //Guardamos refresh token
        newUser.refreshTokens.push(refreshToken);
        await newUser.save();

        res.status(201).json({
            message: 'Usuario creado con éxito',
            accessToken,   // Enviamos el corto
            refreshToken,  // Enviamos el largo
            user: { id: newUser._id, username: newUser.username, email: newUser.email, avatar: newUser.avatar }
        });

    } catch (error) {
        console.error("ERROR EN REGISTRO:", error);
        res.status(500).json({ message: 'Error en el servidor al registrar usuario' });
    }
};

const login = async (req, res) => {
    try {
        const { email, password } = req.body;

        // 1. Buscar si existe un usuario con ese email
        const user = await User.findOne({ email });
        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        // 2. Comprobar si la contraseña es correcta (bcrypt compara la normal con la encriptada)
        const isPasswordCorrect = await bcrypt.compare(password, user.password);
        if (!isPasswordCorrect) {
            return res.status(400).json({ message: 'Contraseña incorrecta' });
        }

        //Generamos tokens
        const accessToken = generateAccessToken(user._id);
        const refreshToken = generateRefreshToken(user._id);

        user.refreshTokens.push(refreshToken);
        await user.save();

        // 4. Enviar los datos al móvil
        res.status(200).json({
            message: 'Login exitoso',
            accessToken,   // Peticiones del día a día
            refreshToken,  // Pase para renovar la sesión
            user: {
                id: user._id,
                username: user.username,
                email: user.email,
                avatar: user.avatar
            }
        });

    } catch (error) {
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
            user: { username: updatedUser.username, email: updatedUser.email, avatar: updatedUser.avatar }
        });

    } catch (error) {
        res.status(500).json({ message: 'Error actualizando el perfil' });
    }
};
const refreshToken = async (req, res) => {
    // El frontend nos enviará su Refresh Token guardado
    const { refreshToken } = req.body;

    if (!refreshToken) {
        return res.status(401).json({ message: 'Se requiere un Refresh Token' });
    }

    try {
        // 1. Verificamos que el token no esté manipulado usando el SECRETO LARGO
        const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
        
        // 2. Buscamos al usuario y comprobamos la BBDD
        const user = await User.findById(decoded.id);
        
        // Si el usuario fue borrado O si el token no está en su lista (fue revocado)
        if (!user || !user.refreshTokens.includes(refreshToken)) {
            return res.status(403).json({ message: 'Refresh Token inválido o revocado' });
        }

        // 3. MAGIA: Todo es correcto, le damos un Access Token NUEVO de 15 min
        // (Asegúrate de que el helper generateAccessToken sigue arriba en tu archivo)
        const newAccessToken = generateAccessToken(user._id);

        res.status(200).json({
            message: 'Token renovado con éxito',
            accessToken: newAccessToken
        });

    } catch (error) {
        // Si el Refresh Token (de 30 días) ha caducado, cae aquí.
        console.error("Error renovando token:", error.message);
        return res.status(403).json({ message: 'Refresh Token expirado. Vuelve a iniciar sesión.' });
    }
};

const logout = async (req, res) => {
    const { refreshToken } = req.body;

    try {
        if (!refreshToken) {
            return res.status(400).json({ message: 'No se proporcionó token para cerrar sesión' });
        }

        // Extraemos el ID del usuario del token
        const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
        const user = await User.findById(decoded.id);

        if (user) {
            // Filtramos el array: nos quedamos con todos los tokens MENOS el que nos han pasado
            user.refreshTokens = user.refreshTokens.filter(token => token !== refreshToken);
            await user.save();
        }

        res.status(200).json({ message: 'Sesión cerrada correctamente en este dispositivo' });

    } catch (error) {
        // Si el token ya había caducado o era inválido, para nosotros ya está "cerrada"
        res.status(200).json({ message: 'Sesión finalizada' });
    }
};

const verifyCurrentPassword = async (req, res) => {
    try {
        const { currentPassword } = req.body;
        const userId = req.user.id;

        const user = await User.findById(userId);
        if (!user) return res.status(404).json({ message: 'Usuario no encontrado' });

        // Comparamos la contraseña enviada con el hash guardado en MongoDB
        const isMatch = await bcrypt.compare(currentPassword, user.password);
        
        if (isMatch) {
            return res.status(200).json({ success: true, message: 'Contraseña correcta' });
        } else {
            return res.status(400).json({ success: false, message: 'Contraseña incorrecta' });
        }
    } catch (error) {
        res.status(500).json({ success: false, message: 'Error del servidor' });
    }
};

const updateAvatar = async (req, res) => {
  try {
    const userId = req.user.id; // Asumiendo que el middleware de auth inyecta el req.user
    const { avatar } = req.body;

    const updatedUser = await User.findByIdAndUpdate(
      userId,
      { avatar },
      { new: true }
    ).select('-password'); // Devolvemos el usuario sin la contraseña

    res.status(200).json({ success: true, user: updatedUser });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error al actualizar el avatar' });
  }
};

module.exports = { register, login, updateUser, refreshToken, logout, verifyCurrentPassword, updateAvatar };