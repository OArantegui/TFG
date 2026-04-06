const axios = require('axios');
const rebrickableService = require('../services/rebrickable.service');
const marketService = require('../services/market.service');

const getThemes = async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const search = req.query.search || '';
        const sort = req.query.sort || 'name_asc';

        const data = await rebrickableService.getThemes(page, search, sort);
        res.status(200).json(data);
    } catch (error) {
        res.status(500).json({ message: 'Error al obtener temas', error: error.message });
    }
};

// ¡Cambiado a 'const' para mantener la consistencia con tu código!
const getSetsByTheme = async (req, res) => {
    try {
        const themeId = req.params.themeId; 
        const page = parseInt(req.query.page) || 1;
        const search = req.query.search || '';

        const data = await rebrickableService.getSetsByTheme(themeId, page, search);
        res.status(200).json(data);
    } catch (error) {
        res.status(500).json({ message: 'Error al obtener sets del tema', error: error.message });
    }
};

const getImageProxy = async (req, res) => {
    const { url } = req.query; 
    
    if (!url) {
        return res.status(400).send('Falta el parámetro url');
    }

    try {
        const response = await axios({
            url: url,
            method: 'GET',
            responseType: 'stream',
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
                'Accept-Encoding': 'gzip, deflate, br'
            }
        });

        res.setHeader('Access-Control-Allow-Origin', '*');
        res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
        res.setHeader('Content-Type', response.headers['content-type']);
        
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
        
        res.status(200).json({ url: imageUrl });
    } catch (error) {
        res.status(200).json({ url: null });
    }
};

const getSetMinifigs = async (req, res) => {
  try {
    const { set_num } = req.params;
    const minifigs = await rebrickableService.getSetMinifigs(set_num);
    
    res.json({
      success: true,
      count: minifigs.length,
      data: minifigs
    });
  } catch (error) {
    res.status(500).json({ 
      success: false, 
      message: 'Error al obtener las minifiguras del set' 
    });
  }
};
const getMinifigSets = async (req, res) => {
  try {
    const { fig_num } = req.params;
    const sets = await rebrickableService.getMinifigSets(fig_num);
    
    res.json({
      success: true,
      count: sets.length,
      data: sets
    });
  } catch (error) {
    res.status(500).json({ 
      success: false, 
      message: 'Error al obtener los sets de la minifigura' 
    });
  }
};
const getAllSets = async (req, res) => {
    try {
        const { page = 1, search = '' } = req.query;
        const data = await rebrickableService.getAllSets(page, search);
        res.json(data);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// GET: Buscar todas las minifiguras (Paginado)
const getMinifigs = async (req, res) => {
    try {
        const page = req.query.page || 1;
        const search = req.query.search || '';

        const data = await rebrickableService.getAllMinifigs(page, search);
        res.status(200).json({ success: true, data });
    } catch (error) {
        console.error("Error obteniendo minifiguras:", error);
        res.status(500).json({ success: false, message: 'Error al obtener minifiguras', error: error.message });
    }
};

// GET: Detalles de una minifigura y en qué sets aparece
const getMinifigDetails = async (req, res) => {
    try {
        const { figNum } = req.params;

        // TFG: Ejecutamos ambas peticiones a Rebrickable en paralelo para reducir el tiempo de respuesta (Latencia)
        const [details, sets] = await Promise.all([
            rebrickableService.getMinifigDetails(figNum),
            rebrickableService.getMinifigSets(figNum)
        ]);

        res.status(200).json({ 
            success: true, 
            data: {
                ...details,
                appearsInSets: sets // Inyectamos los sets en la misma respuesta
            } 
        });
    } catch (error) {
        console.error(`Error obteniendo detalles de la minifigura ${req.params.figNum}:`, error);
        res.status(500).json({ success: false, message: 'Error al obtener detalles', error: error.message });
    }
};

const getSetMarketData = async (req, res) => {
    try {
        const { setId } = req.params;
        
        // CORRECCIÓN 1: Usamos getSetByNum, que es como se llama en tu servicio
        const setDetails = await rebrickableService.getSetByNum(setId);
        
        // CORRECCIÓN 2: Le pasamos setDetails.pieces en lugar de num_parts
        const marketData = marketService.generateMockMarketData(
            setId, 
            setDetails.pieces, 
            setDetails.year
        );

        res.status(200).json(marketData);
    } catch (error) {
        console.error(`Error al obtener mercado para ${req.params.setId}:`, error.message);
        res.status(500).json({ message: 'Error al calcular datos de mercado' });
    }
};

const getThemeById = async (req, res) => {
    try {
        const theme = await rebrickableService.getThemeById(req.params.id);
        res.status(200).json({ success: true, data: theme });
    } catch (error) {
        res.status(500).json({ message: 'Error al obtener tema' });
    }
};


module.exports = {
    getThemes,
    getSetsByTheme,
    getImageProxy,
    getThemeCover,
    getSetMinifigs,
    getMinifigSets,
    getAllSets,
    getMinifigs,
    getMinifigDetails,
    getSetMarketData,
    getThemeById
};