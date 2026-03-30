const axios = require('axios');
require('dotenv').config();

const API_KEY = process.env.REBRICKABLE_API_KEY;
const BASE_URL = process.env.REBRICKABLE_BASE_URL;

const CACHE_TTL_MS = 24 * 60 * 60 * 1000; // 24 horas en milisegundos

// Caché para Portadas de temas
const themeImagesCache = {};
let cachedThemes = null;
let lastThemesFetchTime = 0;

// Caché para Sets individuales (Vital para cargar la Colección y Wishlist al instante)
// Formato: { "42115-1": { timestamp: 162..., data: { ... } } }
const setsCache = {};
// ==========================================

// Configuración base de Axios para no repetir headers
const apiClient = axios.create({
    baseURL: BASE_URL,
    headers: {
        'Authorization': `key ${API_KEY}`,
        'Accept': 'application/json'
    }
});

const getThemes = async () => {
    const currentTime = Date.now();

    // 1. CHEQUEO DE CACHÉ: ¿Tenemos temas y aún no han caducado?
    if (cachedThemes && (currentTime - lastThemesFetchTime < CACHE_TTL_MS)) {
        console.log("⚡ [CACHÉ] Sirviendo lista de Temas desde memoria RAM");
        return cachedThemes;
    }

    try {
        console.log("🌐 [API] Descargando Temas Populares desde Rebrickable...");
        const popularThemeIds = [158, 1, 435, 246, 252, 690, 608, 576, 721, 672, 53];
        const themePromises = popularThemeIds.map(id => apiClient.get(`/themes/${id}/`));
        const responses = await Promise.all(themePromises);

        const themesData = responses.map(response => response.data);
        
        const result = {
            count: themesData.length,
            next: null,
            previous: null,
            results: themesData
        };

        // 2. GUARDADO EN CACHÉ: Actualizamos los datos y la hora
        cachedThemes = result;
        lastThemesFetchTime = currentTime;

        return result;
    } catch (error) {
        console.error("Error en Rebrickable Service (getThemes):", error.message);
        // Salvavidas: Si la API falla, pero tenemos una caché vieja, devolvemos la vieja
        if (cachedThemes) return cachedThemes; 
        throw error;
    }
};

const getSetsByTheme = async (themeId, page = 1, search = '') => {
    try {
        // Nota: Los resultados de búsqueda general no los cacheamos porque 
        // son infinitos y cambian según lo que el usuario busque y pida (paginación).
        let url = `/sets/?theme_id=${themeId}&page_size=20&ordering=-year&page=${page}`;
        
        if (search && search.trim() !== '') {
            url += `&search=${encodeURIComponent(search)}`;
        }

        const response = await apiClient.get(url);
        return response.data; 
    } catch (error) {
        console.error("Error en Rebrickable Service (getSetsByTheme):", error.message);
        throw error;
    }
};

const getThemeCover = async (themeId) => {
    if (themeImagesCache[themeId]) {
        return themeImagesCache[themeId];
    }

    try {
        const response = await apiClient.get(`/sets/?theme_id=${themeId}&page_size=1&ordering=-num_parts`);
        
        let imageUrl = null;
        if (response.data.results && response.data.results.length > 0) {
            imageUrl = response.data.results[0].set_img_url;
        }

        themeImagesCache[themeId] = imageUrl;
        return imageUrl;
    } catch (error) {
        console.error(`Error buscando portada para tema ${themeId}:`, error.message);
        return null; 
    }
};

const getSetByNum = async (setNum) => {
    const currentTime = Date.now();

    // 1. CHEQUEO DE CACHÉ: Ideal para cuando el usuario abre la pestaña de Colección repetidas veces
    if (setsCache[setNum] && (currentTime - setsCache[setNum].timestamp < CACHE_TTL_MS)) {
        console.log(`⚡ [CACHÉ] Sirviendo detalles del Set ${setNum} desde memoria`);
        return setsCache[setNum].data;
    }

    try {
        console.log(`🌐 [API] Descargando detalles del Set ${setNum} desde Rebrickable...`);
        const response = await apiClient.get(`/sets/${setNum}/`);
        const setData = response.data;

        const result = {
            _id: setData.set_num,            
            name: setData.name,
            themeId: setData.theme_id,
            year: setData.year,
            imageUrl: setData.set_img_url,   
            pieces: setData.num_parts,
            lastApiSync: new Date()
        };

        // 2. GUARDADO EN CACHÉ: Almacenamos este set para próximas consultas
        setsCache[setNum] = {
            timestamp: currentTime,
            data: result
        };

        return result;
    } catch (error) {
        console.error(`Error en Rebrickable Service (getSetByNum - ${setNum}):`, error.message);
        
        // Salvavidas de emergencia
        if (setsCache[setNum]) return setsCache[setNum].data;
        throw error; 
    }
};

module.exports = {
    getThemes,
    getSetsByTheme,
    getThemeCover,
    getSetByNum
};