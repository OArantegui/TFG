const axios = require('axios');
const BricksetCache = require('../models/brickset_cache.model'); // Asegúrate de que la ruta sea correcta
require('dotenv').config();

const API_KEY = process.env.BRICKSET_API_KEY;
const BASE_URL = 'https://brickset.com/api/v3.asmx/getSets';

// Función para limpiar el JSON gigante de Brickset y quedarnos solo con lo útil
const mapBricksetData = (rawSet) => {
    // Brickset a veces separa el número de la variante (ej. number: "75192", numberVariant: 1)
    // Lo unimos para que coincida con el formato de Rebrickable ("75192-1")
    const fullSetId = `${rawSet.number}-${rawSet.numberVariant}`;

    return {
        setID: rawSet.setID,
        number: fullSetId,
        name: rawSet.name,
        year: rawSet.year,
        theme: rawSet.theme,
        themeGroup: rawSet.themeGroup,
        subtheme: rawSet.subtheme,
        category: rawSet.category,
        availability: rawSet.availability,
        released: rawSet.released,
        pieces: rawSet.pieces,
        minifigs: rawSet.minifigs,
        launchDate: rawSet.launchDate ? new Date(rawSet.launchDate) : null,
        exitDate: rawSet.exitDate ? new Date(rawSet.exitDate) : null,
        image: rawSet.image,
        LEGOCom: rawSet.LEGOCom,
        rating: rawSet.rating,
        ageRange: rawSet.ageRange,
        dimensions: rawSet.dimensions,
        modelDimensions: rawSet.modelDimensions,
        barcode: rawSet.barcode,
        itemNumber: rawSet.itemNumber
    };
};

/**
 * Obtiene los detalles de un set usando su ID (ej. "42115-1")
 */
const getSetDetails = async (setId) => {
    try {
        // 1. Buscar en nuestra base de datos MongoDB
        const cachedSet = await BricksetCache.findOne({ number: setId });
        
        if (cachedSet) {
            console.log(`⚡ [MONGO] Sirviendo precios y estado del set ${setId} desde base de datos`);
            return cachedSet;
        }

        // 2. Si no existe, llamamos a la API de Brickset
        console.log(`🌐 [API] Descargando datos reales del set ${setId} desde Brickset...`);
        const response = await axios.get(BASE_URL, {
            params: {
                apiKey: API_KEY,
                userHash: '', // No es necesario para búsquedas públicas
                params: JSON.stringify({ setNumber: setId }) // Brickset pide un JSON stringificado aquí
            }
        });

        // Verificamos si la API devolvió resultados
        if (response.data.status === 'success' && response.data.matches > 0) {
            const rawSet = response.data.sets[0];
            
            // 3. Limpiamos los datos
            const cleanData = mapBricksetData(rawSet);

            // 4. Lo guardamos en MongoDB para el futuro
            const savedSet = await BricksetCache.create(cleanData);
            return savedSet;
        } else {
            // Si el set no existe en Brickset, devolvemos null
            return null;
        }

    } catch (error) {
        console.error(`Error en Brickset Service (getSetDetails - ${setId}):`, error.message);
        throw error;
    }
};

/**
 * Busca un set por código de barras escaneado
 */
const getSetByBarcode = async (barcode) => {
    try {
        // 1. Buscar en nuestra base de datos MongoDB (por EAN o UPC)
        const cachedSet = await BricksetCache.findOne({
            $or: [
                { 'barcode.EAN': barcode },
                { 'barcode.UPC': barcode }
            ]
        });
        
        if (cachedSet) {
            console.log(`⚡ [MONGO] Set encontrado por código de barras: ${cachedSet.number}`);
            return cachedSet.number; // Devolvemos el ID tipo "42115-1"
        }

        // 2. Si no está en Mongo, llamamos a la API de Brickset
        console.log(`🌐 [API] Buscando código de barras ${barcode} en Brickset...`);
        const response = await axios.get(BASE_URL, {
            params: {
                apiKey: API_KEY,
                userHash: '',
                params: JSON.stringify({ query: barcode })
            }
        });

        if (response.data.status === 'success' && response.data.matches > 0) {
            const rawSet = response.data.sets[0];
            
            // 3. Limpiamos y guardamos el nuevo set descubierto
            const cleanData = mapBricksetData(rawSet);
            await BricksetCache.create(cleanData);

            // 4. Devolvemos el ID del set para que el frontend pueda cargar los detalles
            return cleanData.number; 
        } else {
            return null; // Código de barras no encontrado
        }

    } catch (error) {
        console.error(`Error en Brickset Service (getSetByBarcode - ${barcode}):`, error.message);
        throw error;
    }
};

module.exports = {
    getSetDetails,
    getSetByBarcode
};