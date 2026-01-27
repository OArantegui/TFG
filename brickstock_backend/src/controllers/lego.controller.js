const axios = require('axios');
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
const getImageProxy = async (req, res) => {
    const { url } = req.query; // Recibimos la URL real como parámetro
    
    if (!url) {
        return res.status(400).send('Falta el parámetro url');
    }

    try {
        // El backend pide la imagen a Rebrickable (sin CORS de por medio)
        const response = await axios({
            url: url,
            method: 'GET',
            responseType: 'stream' // Importante: la bajamos como flujo de datos
        });

        // Copiamos las cabeceras de tipo de imagen (jpg/png)
        res.setHeader('Content-Type', response.headers['content-type']);
        
        // "Enchufamos" la descarga directamente a la respuesta del cliente
        response.data.pipe(res);
    } catch (error) {
        console.error("Error proxy imagen:", error.message);
        res.status(404).send('Imagen no encontrada');
    }
};
module.exports = {
    getThemes,
    getSets,
    getImageProxy
};