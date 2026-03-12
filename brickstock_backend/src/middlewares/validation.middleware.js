const { body, validationResult } = require('express-validator');

// 1. Función genérica para comprobar si hay errores de validación
// TFG Info: Este es el middleware real que lee los resultados de las reglas que definiremos abajo.
exports.checkValidationErrors = (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        // Si hay errores, cortamos aquí y devolvemos un 400 con la lista de fallos
        return res.status(400).json({ 
            success: false, 
            message: 'Error en los datos enviados',
            errors: errors.array() 
        });
    }
    // Si todo está limpio, pasamos al controlador
    next();
};

// 2. Reglas de Validación para añadir a la Cartera (Portfolio)
exports.validateCollectionInput = [
    // Verificamos que envían un setNum y que es texto
    body('setNum')
        .exists().withMessage('El número de set (setNum) es obligatorio')
        .isString().withMessage('El número de set debe ser texto')
        .trim().notEmpty().withMessage('El número de set no puede estar vacío'),
    
    // Verificamos la cantidad (debe ser número entero y mínimo 1)
    body('quantity')
        .optional() // Es opcional porque nuestro modelo le pone 1 por defecto
        .isInt({ min: 1 }).withMessage('La cantidad debe ser un número entero mayor o igual a 1'),
    
    // Verificamos el precio de compra (debe ser número y no negativo)
    body('purchasePrice')
        .exists().withMessage('El precio de compra es obligatorio')
        .isFloat({ min: 0 }).withMessage('El precio de compra debe ser un número positivo o 0'),
    
    // Verificamos la condición (solo permitimos los valores definidos)
    body('condition')
        .optional()
        .isIn(['NISB', 'Used', 'Incomplete']).withMessage('Condición no válida')
];

// 3. Reglas de Validación para la Lista de Deseos (Wishlist)
exports.validateWishlistInput = [
    body('setNum')
        .exists().withMessage('El número de set (setNum) es obligatorio')
        .isString().withMessage('El número de set debe ser texto')
        .trim().notEmpty(),
    
    body('targetPrice')
        .optional()
        .isFloat({ min: 0 }).withMessage('El precio objetivo debe ser un número positivo o 0')
];