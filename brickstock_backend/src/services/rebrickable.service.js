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
    const response = await apiClient.get(`/sets/${setNum}/minifigs/`);
    
    // TFG: Mapeamos los datos. Como la API v3 trata a las minifiguras 
    // como "sets" con el prefijo "fig-", la respuesta es plana.
    return response.data.results.map(item => ({
      // Usamos el fallback (||) por si acaso la API decide cambiar 
      // y enviarnos fig_num en el futuro (programación defensiva).
      figNum: item.set_num || item.fig_num,
      name: item.set_name || item.name,
      imageUrl: item.set_img_url || item.fig_url || '', 
      quantity: item.quantity || 1
    }));
  } catch (error) {
    console.error(`Error fetching minifigs for set ${setNum} from Rebrickable:`, error.message);
    throw error;
  }
};

const getMinifigSets = async (figNum) => {
  try {
    // La API de Rebrickable usa la ruta /minifigs/{fig_num}/sets/
    const response = await apiClient.get(`/minifigs/${figNum}/sets/`);
    
    // Mapeamos los datos simulando la estructura que espera tu modelo LegoSet de Flutter
    return response.data.results.map(item => ({
      setNum: item.set_num,
      name: item.name,
      year: item.year || 0,
      themeId: item.theme_id || 0,
      numParts: item.num_parts || 0,
      imageUrl: item.set_img_url || ''
    }));
  } catch (error) {
    console.error(`Error fetching sets for minifig ${figNum}:`, error.message);
    throw error;
  }
};
const getAllSets = async (page = 1, search = '') => {
    try {
        let url = `/sets/?page_size=20&ordering=-year&page=${page}`;
        
        if (search && search.trim() !== '') {
            url += `&search=${encodeURIComponent(search)}`;
        }

        const response = await apiClient.get(url);
        return response.data; 
    } catch (error) {
        console.error("Error en Rebrickable Service (getAllSets):", error.message);
        throw error;
    }
};
// Obtener lista paginada de minifiguras (para el buscador del Frontend)
const getAllMinifigs = async (page = 1, search = '') => {
    try {
        let url = `/minifigs/?page_size=20&page=${page}`;
        if (search && search.trim() !== '') {
            url += `&search=${encodeURIComponent(search)}`;
        }
        const response = await apiClient.get(url);
        return response.data;
    } catch (error) {
        console.error("Error en Rebrickable Service (getAllMinifigs):", error.message);
        throw error;
    }
};

// Obtener detalles de una minifigura concreta
const getMinifigDetails = async (figNum) => {
    try {
        const response = await apiClient.get(`/minifigs/${figNum}/`);
        return response.data;
    } catch (error) {
        console.error(`Error en Rebrickable Service (getMinifigDetails - ${figNum}):`, error.message);
        throw error;
    }
};

module.exports = {
    getThemes,
    getSetsByTheme,
    getThemeCover,
    getSetByNum,
    getSetMinifigs,
    getMinifigSets,
    getAllSets,
    getAllMinifigs,
    getMinifigDetails
};