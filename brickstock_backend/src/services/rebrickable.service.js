const axios = require('axios');
require('dotenv').config();

const API_KEY = process.env.REBRICKABLE_API_KEY;
const BASE_URL = process.env.REBRICKABLE_BASE_URL;

// Evita que hagamos 50 llamadas a Rebrickable cada vez que entramos a Explorar
const themeImagesCache = {};

// Configuración base de Axios para no repetir headers
const apiClient = axios.create({
    baseURL: BASE_URL,
    headers: {
        'Authorization': `key ${API_KEY}`,
        'Accept': 'application/json'
    }
});

const getThemes = async () => {
    try {
        // Pedimos 50 temas
        const response = await apiClient.get('/themes/?page_size=50');
        return response.data;
    } catch (error) {
        console.error("Error en Rebrickable Service (getThemes):", error.message);
        throw error;
    }
};

const getSetsByTheme = async (themeId) => {
    try {
        const response = await apiClient.get(`/sets/?theme_id=${themeId}&page_size=20`);
        return response.data;
    } catch (error) {
        console.error("Error en Rebrickable Service (getSetsByTheme):", error.message);
        throw error;
    }
};
const getThemeCover = async (themeId) => {
    // 1. Si ya tenemos la imagen en caché, la devolvemos directo (Ahorro de API)
    if (themeImagesCache[themeId]) {
        return themeImagesCache[themeId];
    }

    try {
        // 2. Si no, la pedimos a Rebrickable
        // page_size=1: Solo queremos 1
        // ordering=-num_parts: El set más grande suele ser el mejor para la portada
        const response = await apiClient.get(`/sets/?theme_id=${themeId}&page_size=1&ordering=-num_parts`);
        
        let imageUrl = null;
        if (response.data.results && response.data.results.length > 0) {
            imageUrl = response.data.results[0].set_img_url;
        }

        // 3. Guardamos en caché (aunque sea null, para no volver a intentarlo inútilmente)
        themeImagesCache[themeId] = imageUrl;
        
        return imageUrl;
    } catch (error) {
        console.error(`Error buscando portada para tema ${themeId}:`, error.message);
        return null; 
    }
};
module.exports = {
    getThemes,
    getSetsByTheme,
    getThemeCover
};