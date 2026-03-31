const axios = require('axios');
require('dotenv').config();

const API_KEY = process.env.REBRICKABLE_API_KEY;
const BASE_URL = process.env.REBRICKABLE_BASE_URL;

const CACHE_TTL_MS = 24 * 60 * 60 * 1000; // 24 horas en milisegundos

// Caché para Portadas de temas
const themeImagesCache = {};
let cachedThemes = null;
let lastThemesFetchTime = 0;
let allThemesCache = [];

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

const getThemes = async (page = 1, search = '', sort = 'name_asc') => {
    const currentTime = Date.now();
    const pageSize = 20;

    try {
        // 1. CACHÉ TOTAL: Si no tenemos temas o caducaron, pedimos TODOS de golpe (max 1000)
        if (allThemesCache.length === 0 || (currentTime - lastThemesFetchTime > CACHE_TTL_MS)) {
            console.log("🌐 [API] Descargando TODOS los temas de Rebrickable...");
            const response = await apiClient.get('/themes/?page_size=1000');
            allThemesCache = response.data.results;
            lastThemesFetchTime = currentTime;
        }

        // 2. BÚSQUEDA (Search)
        let filteredThemes = allThemesCache;
        if (search && search.trim() !== '') {
            const searchLower = search.toLowerCase();
            filteredThemes = allThemesCache.filter(theme => 
                theme.name.toLowerCase().includes(searchLower)
            );
        }

        // 3. ORDENACIÓN (Sorting)
        filteredThemes.sort((a, b) => {
            if (sort === 'name_asc') return a.name.localeCompare(b.name);
            if (sort === 'name_desc') return b.name.localeCompare(a.name);
            if (sort === 'id_asc') return a.id - b.id;
            if (sort === 'id_desc') return b.id - a.id;
            return 0;
        });

        // 4. PAGINACIÓN (Slice)
        const startIndex = (page - 1) * pageSize;
        const endIndex = startIndex + pageSize;
        const paginatedThemes = filteredThemes.slice(startIndex, endIndex);

        return {
            count: filteredThemes.length,
            page: parseInt(page),
            totalPages: Math.ceil(filteredThemes.length / pageSize),
            results: paginatedThemes
        };
    } catch (error) {
        console.error("Error en getThemes:", error.message);
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

const getSetMinifigs = async (setNum) => {
  try {
    // TFG: Usamos tu instancia apiClient que ya inyecta el API Key y la Base URL automáticamente.
    // La ruta oficial de Rebrickable v3 es /sets/{set_num}/minifigs/
    const response = await apiClient.get(`/sets/${setNum}/minifigs/`);
    
    // Mapeamos los datos para enviar un payload limpio al frontend (BFF Pattern)
    return response.data.results.map(item => ({
      figNum: item.minifig.fig_num,
      name: item.minifig.name,
      imageUrl: item.minifig.fig_url, // Puede venir nulo si la figura no tiene foto
      quantity: item.quantity
    }));
  } catch (error) {
    console.error(`Error fetching minifigs for set ${setNum} from Rebrickable:`, error.message);
    throw error;
  }
};

module.exports = {
    getThemes,
    getSetsByTheme,
    getThemeCover,
    getSetByNum,
    getSetMinifigs
};