const axios = require('axios');
require('dotenv').config();

const API_KEY = process.env.REBRICKABLE_API_KEY;
const BASE_URL = process.env.REBRICKABLE_BASE_URL;

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

module.exports = {
    getThemes,
    getSetsByTheme
};