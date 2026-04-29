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

// Caché para Sets individuales
const setsCache = {};

// Diccionarios de caché para evitar el límite de la API
const setMinifigsCache = {}; 
const minifigSetsCache = {};
const minifigDetailsCache = {};
const queryCache = {}; // Para las búsquedas generales (getAllSets, getAllMinifigs)
const QUERY_CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutos para búsquedas


// Configuración base de Axios para no repetir headers
const apiClient = axios.create({
    baseURL: BASE_URL,
    headers: {
        'Authorization': `key ${API_KEY}`,
        'Accept': 'application/json'
    }
});

// Usamos un pequeño caché en memoria para no saturar Rebrickable
const themeDetailsCache = {};

const getThemeById = async (themeId) => {
    // Si ya lo buscamos antes, lo devolvemos al instante
    if (themeDetailsCache[themeId]) return themeDetailsCache[themeId];

    try {
        // Usamos nuestro apiClient configurado
        const response = await apiClient.get(`/themes/${themeId}/`);
        themeDetailsCache[themeId] = response.data;
        return response.data;
    } catch (error) {
        console.error(`Error al obtener el tema ${themeId}:`, error.message);
        return { name: `Tema ${themeId}` }; // Fallback de seguridad
    }
};

const getThemes = async (page = 1, search = '', sort = 'id_desc') => {
    const currentTime = Date.now();
    const pageSize = 20;

    try {
        // Pedimos TODOS de golpe (max 1000)
        if (allThemesCache.length === 0 || (currentTime - lastThemesFetchTime > CACHE_TTL_MS)) {
            console.log("Descargando TODOS los temas de Rebrickable...");
            const response = await apiClient.get('/themes/?page_size=1000');
            allThemesCache = response.data.results;
            lastThemesFetchTime = currentTime;
        }

        // Creamos un diccionario para búsquedas ultra rápidas O(1)
        const themeDict = {};
        allThemesCache.forEach(t => themeDict[t.id] = t);

        // Función recursiva para obtener la ruta completa
        const getFullThemeName = (theme) => {
            if (!theme) return "";
            if (!theme.parent_id) return theme.name; // Es un tema raíz
            
            const parent = themeDict[theme.parent_id];
            if (parent) {
                return `${getFullThemeName(parent)} > ${theme.name}`;
            }
            return theme.name;
        };

        // Enriquecemos todos los temas con su nombre completo
        const enrichedThemes = allThemesCache.map(theme => ({
            ...theme,
            fullName: getFullThemeName(theme)
        }));

        let filteredThemes = enrichedThemes;
        if (search && search.trim() !== '') {
            const searchLower = search.toLowerCase();
            filteredThemes = enrichedThemes.filter(theme => 
                theme.fullName.toLowerCase().includes(searchLower)
            );
        }

        // Ordenamos por el nombre jerárquico
        filteredThemes.sort((a, b) => {
            if (sort === 'name_asc') return a.fullName.localeCompare(b.fullName);
            if (sort === 'name_desc') return b.fullName.localeCompare(a.fullName);
            if (sort === 'id_asc') return a.id - b.id;
            if (sort === 'id_desc') return b.id - a.id;
            return 0;
        });

        // PAGINACIÓN (Slice)
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
        let url = `/sets/?theme_id=${themeId}&page_size=20&ordering=-year&page=${page}`;
        
        if (search && search.trim() !== '') {
            url += `&search=${encodeURIComponent(search)}`;
        }

        // Mini-caché de 5 min para evitar repetir la misma página al hacer scroll
        const currentTime = Date.now();
        if (queryCache[url] && (currentTime - queryCache[url].timestamp < QUERY_CACHE_TTL_MS)) {
            return queryCache[url].data;
        }

        const response = await apiClient.get(url);
        queryCache[url] = { timestamp: currentTime, data: response.data }; 
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

    if (setsCache[setNum] && (currentTime - setsCache[setNum].timestamp < CACHE_TTL_MS)) {
        console.log(`Sirviendo detalles del Set ${setNum} desde memoria`);
        return setsCache[setNum].data;
    }

    try {
        console.log(`Descargando detalles del Set ${setNum} desde Rebrickable...`);
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

        // Almacenamos este set para próximas consultas
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
  // Chequeo de caché
  const currentTime = Date.now();
  if (setMinifigsCache[setNum] && (currentTime - setMinifigsCache[setNum].timestamp < CACHE_TTL_MS)) {
      return setMinifigsCache[setNum].data;
  }

  try {
    const response = await apiClient.get(`/sets/${setNum}/minifigs/`);
    
    // Mapeamos los datos.
    const result = response.data.results.map(item => ({
      //Planeamos posibles distintos nombres
      figNum: item.set_num || item.fig_num,
      name: item.set_name || item.name,
      imageUrl: item.set_img_url || item.fig_url || '', 
      quantity: item.quantity || 1
    }));

    // Guardar en caché
    setMinifigsCache[setNum] = { timestamp: currentTime, data: result };
    return result;

  } catch (error) {
    console.error(`Error fetching minifigs for set ${setNum} from Rebrickable:`, error.message);
    if (setMinifigsCache[setNum]) return setMinifigsCache[setNum].data; // AÑADIDO: Salvavidas
    throw error;
  }
};

const getMinifigSets = async (figNum) => {
  // Chequeo de caché
  const currentTime = Date.now();
  if (minifigSetsCache[figNum] && (currentTime - minifigSetsCache[figNum].timestamp < CACHE_TTL_MS)) {
      return minifigSetsCache[figNum].data;
  }

  try {
    // La API de Rebrickable usa la ruta /minifigs/{fig_num}/sets/
    const response = await apiClient.get(`/minifigs/${figNum}/sets/`);
    
    // Mapeamos los datos simulando la estructura que espera el modelo LegoSet de Flutter
    const result = response.data.results.map(item => {
      const setData = item.set || item; 

      return {
        setNum: setData.set_num,
        name: setData.name,
        year: setData.year || 0,
        themeId: setData.theme_id || 0,
        numParts: setData.num_parts || 0,
        imageUrl: setData.set_img_url || ''
      };
    });

    // Guardar en caché
    minifigSetsCache[figNum] = { timestamp: currentTime, data: result };
    return result;

  } catch (error) {
    console.error(`Error fetching sets for minifig ${figNum}:`, error.message);
    if (minifigSetsCache[figNum]) return minifigSetsCache[figNum].data; // Salvavidas
    throw error;
  }
};

const getAllSets = async (page = 1, search = '') => {
    try {
        let url = `/sets/?page_size=20&ordering=-year&page=${page}`;
        
        if (search && search.trim() !== '') {
            url += `&search=${encodeURIComponent(search)}`;
        }

        // Mini-caché para la consulta
        const currentTime = Date.now();
        if (queryCache[url] && (currentTime - queryCache[url].timestamp < QUERY_CACHE_TTL_MS)) {
            return queryCache[url].data;
        }

        const response = await apiClient.get(url);
        queryCache[url] = { timestamp: currentTime, data: response.data };
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

        // Mini-caché para la consulta
        const currentTime = Date.now();
        if (queryCache[url] && (currentTime - queryCache[url].timestamp < QUERY_CACHE_TTL_MS)) {
            return queryCache[url].data;
        }

        const response = await apiClient.get(url);
        queryCache[url] = { timestamp: currentTime, data: response.data };
        return response.data;
    } catch (error) {
        console.error("Error en Rebrickable Service (getAllMinifigs):", error.message);
        throw error;
    }
};

// Obtener detalles de una minifigura concreta
const getMinifigDetails = async (figNum) => {
    // Chequeo de caché
    const currentTime = Date.now();
    if (minifigDetailsCache[figNum] && (currentTime - minifigDetailsCache[figNum].timestamp < CACHE_TTL_MS)) {
        return minifigDetailsCache[figNum].data;
    }

    try {
        const response = await apiClient.get(`/minifigs/${figNum}/`);
        minifigDetailsCache[figNum] = { timestamp: currentTime, data: response.data };
        return response.data;
    } catch (error) {
        console.error(`Error en Rebrickable Service (getMinifigDetails - ${figNum}):`, error.message);
        if (minifigDetailsCache[figNum]) return minifigDetailsCache[figNum].data; //Salvavidas
        throw error;
    }
};
// Sube por el árbol genealógico de temas hasta encontrar el Tema Principal (Raíz)
const getRootThemeId = async (themeId) => {
    try {
        // Nos aseguramos de que la caché de temas está cargada
        if (allThemesCache.length === 0) {
            await getThemes(1, '', 'id_desc'); // Forzamos la descarga de todos
        }
        
        const themeDict = {};
        allThemesCache.forEach(t => themeDict[t.id] = t);

        let currentThemeId = themeId;
        
        // Mientras el tema actual tenga un padre, seguimos subiendo
        while (currentThemeId && themeDict[currentThemeId] && themeDict[currentThemeId].parent_id) {
            currentThemeId = themeDict[currentThemeId].parent_id;
        }
        
        return currentThemeId;
    } catch (error) {
        console.error("Error buscando el tema raíz:", error.message);
        return themeId; // Fallback de seguridad: devolvemos el original si falla
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
    getMinifigDetails,
    getThemeById,
    getRootThemeId
};