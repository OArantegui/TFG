const jwt = require('jsonwebtoken');

// TFG Info: Creamos un middleware que intercepta la petición ANTES de que llegue al controlador.
exports.verifyJWT = (req, res, next) => {
    try {
        // 1. Buscamos la cabecera 'Authorization' que nos mandará Flutter
        const authHeader = req.header('Authorization');

        // Si no hay cabecera o no empieza por 'Bearer ', puerta.
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ 
                success: false, 
                message: 'Acceso denegado: Formato de token inválido o no proporcionado.' 
            });
        }

        // 2. Extraemos el token (quitando la palabra "Bearer ")
        const token = authHeader.split(' ')[1];

        // 3. Verificamos que el token es real y fue firmado por nuestro servidor
        // OJO: Necesitas tener JWT_SECRET definido en tu archivo .env
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        // 4. LA MAGIA: Guardamos los datos decodificados del usuario (su ID) dentro del objeto 'req'
        // Así, en el portfolio.controller.js podremos hacer: req.user.id
        req.user = decoded;

        // 5. Todo está correcto. Le decimos a Express "puedes continuar hacia el controlador"
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