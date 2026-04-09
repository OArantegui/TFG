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
            // Verificar la edad de la caché
            const THIRTY_DAYS_IN_MS = 30 * 24 * 60 * 60 * 1000;
            const cacheAge = Date.now() - new Date(cachedSet.lastUpdatedServer).getTime();

            // Si tiene menos de 30 días, lo servimos desde BD
            if (cacheAge < THIRTY_DAYS_IN_MS) {
                console.log(`⚡ [MONGO] Sirviendo set ${setId} desde caché (Válida)`);
                return cachedSet;
            }
            
            // Si pasamos de aquí, la caché está caducada
            console.log(`🔄 [CACHE EXPIRADA] El set ${setId} lleva >30 días. Refrescando datos...`);
        }

        // 2. Si no existe o está caducado, llamamos a la API de Brickset
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
            
            // Actualizamos explícitamente el campo de control
            cleanData.lastUpdatedServer = Date.now();

            // 4. Guardamos o actualizamos en MongoDB usando patrón Upsert
            const savedSet = await BricksetCache.findOneAndUpdate(
                { number: setId },         // Condición de búsqueda
                { $set: cleanData },       // Datos a actualizar
                { new: true, upsert: true } // Opciones: 'new' devuelve el doc actualizado, 'upsert' lo crea si no existe
            );
            
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
            // Verificar la edad de la caché
            const THIRTY_DAYS_IN_MS = 30 * 24 * 60 * 60 * 1000;
            const cacheAge = Date.now() - new Date(cachedSet.lastUpdatedServer).getTime();

            // Si tiene menos de 30 días, lo servimos desde BD
            if (cacheAge < THIRTY_DAYS_IN_MS) {
                console.log(`⚡ [MONGO] Set encontrado por código de barras (Caché válida): ${cachedSet.number}`);
                return cachedSet.number; // Devolvemos el ID tipo "42115-1"
            }
            
            // Si pasamos de aquí, la caché está caducada
            console.log(`🔄 [CACHE EXPIRADA] El set del código ${barcode} lleva >30 días. Refrescando datos...`);
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
            
            // 3. Limpiamos los datos y actualizamos la marca de tiempo
            const cleanData = mapBricksetData(rawSet);
            cleanData.lastUpdatedServer = Date.now();

            // 4. Upsert (Actualizar o Insertar)
            // IMPORTANTE: Usamos 'cleanData.number' como filtro para que actualice 
            // el set correcto si ya existía en la base de datos
            await BricksetCache.findOneAndUpdate(
                { number: cleanData.number }, // Condición de búsqueda
                { $set: cleanData },          // Nuevos datos
                { new: true, upsert: true }   // Insertar si no existe
            );

            // 5. Devolvemos el ID del set para que el frontend pueda cargar los detalles
            return cleanData.number; 
        } else {
            return null; // Código de barras no encontrado
        }

    } catch (error) {
        console.error(`Error en Brickset Service (getSetByBarcode - ${barcode}):`, error.message);
        throw error;
    }
};

/**
 * Obtiene las instrucciones de montaje de un set usando su ID
 */
const getInstructions = async (setId) => {
    try {
        // 1. Necesitamos el 'setID' interno de Brickset (ej: 34522), no el '75331-1'
        let cachedSet = await BricksetCache.findOne({ number: setId });
        
        // Si por algún motivo no lo tenemos en caché, lo descargamos primero
        if (!cachedSet) {
            cachedSet = await getSetDetails(setId);
            // Si después de buscarlo en la API sigue sin existir, salimos
            if (!cachedSet) return [];
        }

        const internalSetID = cachedSet.setID; // Este es el número entero que quiere Brickset

        // 2. Llamada a la API de Brickset con el parámetro directo
        const response = await axios.get('https://brickset.com/api/v3.asmx/getInstructions', {
            params: {
                apiKey: API_KEY,
                setID: internalSetID 
            }
        });

        if (response.data.status === 'success' && response.data.matches > 0) {
            return response.data.instructions;
        }
        return [];
    } catch (error) {
        console.error(`Error en Brickset Service (getInstructions - ${setId}):`, error.message);
        throw error;
    }
};

module.exports = {
    getSetDetails,
    getSetByBarcode,
    getInstructions
};