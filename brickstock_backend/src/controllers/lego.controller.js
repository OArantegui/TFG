const rebrickableService = require('../services/rebrickable.service');

const getThemes = async (req, res) => {
    try {
        const data = await rebrickableService.getThemes();
        // Aquí podríamos filtrar datos que el frontend no necesita antes de enviarlos
        res.status(200).json(data);
    } catch (error) {
        res.status(500).json({ message: 'Error al obtener temas', error: error.message });
    }
};

const getSets = async (req, res) => {
    try {
        const { themeId } = req.params; // Obtenemos el ID de la URL
        if (!themeId) {
            return res.status(400).json({ message: 'Falta el parámetro themeId' });
        }
        const data = await rebrickableService.getSetsByTheme(themeId);
        res.status(200).json(data);
    } catch (error) {
        res.status(500).json({ message: 'Error al obtener sets', error: error.message });
    }
};

module.exports = {
    getThemes,
    getSets
};