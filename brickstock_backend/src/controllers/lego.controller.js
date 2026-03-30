const axios = require('axios');
const rebrickableService = require('../services/rebrickable.service');

const getThemes = async (req, res) => {
    try {
        // Extraemos página, búsqueda y orden de la query de la URL
        const page = parseInt(req.query.page) || 1;
        const search = req.query.search || '';
        const sort = req.query.sort || 'name_asc';

        const data = await rebrickableService.getThemes(page, search, sort);
        res.status(200).json(data);
    } catch (error) {
        res.status(500).json({ message: 'Error al obtener temas', error: error.message });
    }
};

//Obtener sets
const getSets = async (req, res) => {
    try {
        const { themeId } = req.params; 
        // Extraemos 'page' y 'search' de la query (?page=2&search=X-Wing)
        const { page, search } = req.query; 

        if (!themeId) {
            return res.status(400).json({ message: 'Falta el parámetro themeId' });
        }
        
        // Le pasamos todo al servicio
        const data = await rebrickableService.getSetsByTheme(themeId, page, search);
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
        const response = await axios({
            url: url,
            method: 'GET',
            responseType: 'stream',
            // 1. CAMUFLAJE: Engañamos a Rebrickable para que crea que somos Google Chrome
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
                'Accept-Encoding': 'gzip, deflate, br'
            }
        });

        // 2. CABECERAS PARA FLUTTER WEB (CanvasKit)
        // Forzamos que cualquier navegador acepte esta imagen sin rechistar
        res.setHeader('Access-Control-Allow-Origin', '*');
        res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
        res.setHeader('Content-Type', response.headers['content-type']);
        
        // 3. Pasamos el flujo de datos al cliente
        response.data.pipe(res);
    } catch (error) {
        console.error("Error proxy imagen:", error.message);
        res.status(404).send('Imagen no encontrada');
    }
};

const getThemeCover = async (req, res) => {
    try {
        const { themeId } = req.params;
        const imageUrl = await rebrickableService.getThemeCover(themeId);
        
        // Devolvemos un JSON simple
        res.status(200).json({ url: imageUrl });
    } catch (error) {
        // No fallamos estrepitosamente, si hay error devolvemos url null
        res.status(200).json({ url: null });
    }
};

module.exports = {
    getThemes,
    getSets,
    getImageProxy,
    getThemeCover
};