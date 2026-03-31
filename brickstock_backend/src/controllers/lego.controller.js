const axios = require('axios');
const rebrickableService = require('../services/rebrickable.service');

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

module.exports = {
    getThemes,
    getSetsByTheme,
    getImageProxy,
    getThemeCover,
    getSetMinifigs,
    getMinifigSets,
    getAllSets
};