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
        const popularThemeIds = [158, 1, 435, 246, 252, 690, 608, 576, 721, 672, 53];
        // Pedimos 50 temas
        const themePromises = popularThemeIds.map(id => apiClient.get(`/themes/${id}/`));
        const responses = await Promise.all(themePromises);

        const themesData = responses.map(response => response.data);
        return {
                count: themesData.length,
                next: null,
                previous: null,
                results: themesData
        };
    } catch (error) {
        console.error("Error en Rebrickable Service (getThemes):", error.message);
        throw error;
    }
};

const getSetsByTheme = async (themeId) => {
    try {
        const response = await apiClient.get(`/sets/?theme_id=${themeId}&page_size=20&ordering=-year`);
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

const getSetByNum = async (setNum) => {
    try {
        const response = await apiClient.get(`/sets/${setNum}/`);
        const setData = response.data;

        // Mapeamos el JSON de Rebrickable a NUESTRO formato de MongoDB (SetCache)
        return {
            _id: setData.set_num,            
            name: setData.name,
            themeId: setData.theme_id,
            year: setData.year,
            imageUrl: setData.set_img_url,   
            pieces: setData.num_parts,
            lastApiSync: new Date()
        };
    } catch (error) {
        console.error(`Error en Rebrickable Service (getSetByNum - ${setNum}):`, error.message);
        throw error; // Lanzamos el error para que el Controlador (ej. collection.controller) lo maneje
    }
};

module.exports = {
    getThemes,
    getSetsByTheme,
    getThemeCover,
    getSetByNum
};