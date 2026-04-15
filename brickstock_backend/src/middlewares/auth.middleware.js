const jwt = require('jsonwebtoken');

// Middleware que intercepta la petición ANTES de que llegue al controlador.
exports.verifyJWT = (req, res, next) => {
    try {
        // Buscamos la cabecera 'Authorization' que nos mandará Flutter
        const authHeader = req.header('Authorization');

        // Si no hay cabecera o no empieza por 'Bearer ', denegamos.
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ 
                success: false, 
                message: 'Acceso denegado: Formato de token inválido o no proporcionado.' 
            });
        }

        //Extraemos el token
        const token = authHeader.split(' ')[1];

        //Verificamos que el token es real y fue firmado por nuestro servidor
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        //Guardamos los datos decodificados del usuario (su ID) dentro del objeto 'req'
        req.user = decoded;

        next();

    } catch (error) {
        // Si el token ha caducado o es inventado, el jwt.verify saltará a este catch
        return res.status(401).json({ 
            success: false, 
            message: 'Acceso denegado: Token inválido o expirado.',
            error: error.message
        });
    }
};