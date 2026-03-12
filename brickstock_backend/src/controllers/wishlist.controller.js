const Wishlist = require('../models/wishlist.model');

// POST: Añadir un set a la lista de deseos
exports.addSetToWishlist = async (req, res) => {
    try {
        // TFG Info: Gracias al middleware, aquí ya podemos confiar ciegamente en req.body
        res.status(201).json({ message: "Endpoint para añadir a wishlist protegido y listo (Lógica pendiente)" });
    } catch (error) {
        res.status(500).json({ message: 'Error en el servidor', error: error.message });
    }
};

// GET: Obtener toda la wishlist del usuario
exports.getUserWishlist = async (req, res) => {
    try {
        res.status(200).json({ message: "Endpoint para ver wishlist protegido y listo (Lógica pendiente)" });
    } catch (error) {
        res.status(500).json({ message: 'Error al obtener la wishlist', error: error.message });
    }
};

// PUT: Modificar un elemento de la wishlist (ej. cambiar el targetPrice)
exports.updateWishlistItem = async (req, res) => {
    try {
        res.status(200).json({ message: `Actualizar set con ID ${req.params.id} en wishlist protegido (Lógica pendiente)` });
    } catch (error) {
         res.status(500).json({ message: 'Error al actualizar', error: error.message });
    }
};

// DELETE: Quitar un set de la lista de deseos
exports.removeSetFromWishlist = async (req, res) => {
    try {
        res.status(200).json({ message: `Borrar set con ID ${req.params.id} de la wishlist protegido (Lógica pendiente)` });
    } catch (error) {
         res.status(500).json({ message: 'Error al borrar', error: error.message });
    }
};