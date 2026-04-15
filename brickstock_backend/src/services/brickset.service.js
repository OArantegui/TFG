const axios = require('axios');
const BricksetCache = require('../models/brickset_cache.model');
require('dotenv').config();

const API_KEY = process.env.BRICKSET_API_KEY;
const BASE_URL = 'https://brickset.com/api/v3.asmx/getSets';

// Usamos solo lo que nos interesa para no sobrecargar BBDD
const mapBricksetData = (rawSet) => {
    // Unimos el numero con el variante
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

//Obtiene los detalles de un set usando su ID (ej. "42115-1")
const getSetDetails = async (setId) => {
    try {
        // Buscar en nuestra base de datos
        const cachedSet = await BricksetCache.findOne({ number: setId });
        
        if (cachedSet) {
            // Verificar cuanto lleva de caché
            const THIRTY_DAYS_IN_MS = 30 * 24 * 60 * 60 * 1000;
            const cacheAge = Date.now() - new Date(cachedSet.lastUpdatedServer).getTime();

            // Si lleva menos de 30 días, lo servimos desde BD
            if (cacheAge < THIRTY_DAYS_IN_MS) {
                console.log(`Sirviendo set ${setId} desde bbdd`);
                return cachedSet;
            }
            
            //Mensaje cache caducada
            console.log(`El set ${setId} lleva >30 días en bbdd. Refrescando datos...`);
        }

        //Si no existe o está caducado, llamamos a la API de Brickset
        console.log(`Descargando datos reales del set ${setId} desde Brickset...`);
        const response = await axios.get(BASE_URL, {
            params: {
                apiKey: API_KEY,
                userHash: '', // Campo de brickset, no es necesario para búsquedas públicas
                params: JSON.stringify({ setNumber: setId }) // Brickset pide un JSON stringificado aquí
            }
        });

        // Verificamos si la API devolvió resultados
        if (response.data.status === 'success' && response.data.matches > 0) {
            const rawSet = response.data.sets[0];
            
            // Limpiamos los datos como nos interesa
            const cleanData = mapBricksetData(rawSet);
            
            // Actualizamos el campo de control
            cleanData.lastUpdatedServer = Date.now();

            // Guardamos o actualizamos en bbdd usando patrón Upsert
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

//Busca un set por código de barras escaneado
const getSetByBarcode = async (barcode) => {
    try {
        // Buscar en base de datos (por EAN o UPC)
        const cachedSet = await BricksetCache.findOne({
            $or: [
                { 'barcode.EAN': barcode },
                { 'barcode.UPC': barcode }
            ]
        });
        
        if (cachedSet) {
            // Verificar cuanto lleva de caché
            const THIRTY_DAYS_IN_MS = 30 * 24 * 60 * 60 * 1000;
            const cacheAge = Date.now() - new Date(cachedSet.lastUpdatedServer).getTime();

            // Si lleva menos de 30 días, lo servimos desde bbdd
            if (cacheAge < THIRTY_DAYS_IN_MS) {
                console.log(`Set encontrado por código de barras: ${cachedSet.number}`);
                return cachedSet.number;
            }
            
            // Mensaje caché caducada
            console.log(`El set del código ${barcode} lleva >30 días. Refrescando datos...`);
        }

        // Si no está en Mongo, llamamos a la API de Brickset
        console.log(`Buscando código de barras ${barcode} en Brickset...`);
        const response = await axios.get(BASE_URL, {
            params: {
                apiKey: API_KEY,
                userHash: '',
                params: JSON.stringify({ query: barcode })
            }
        });

        if (response.data.status === 'success' && response.data.matches > 0) {
            const rawSet = response.data.sets[0];
            
            // Limpiamos los datos y actualizamos la marca de tiempo
            const cleanData = mapBricksetData(rawSet);
            cleanData.lastUpdatedServer = Date.now();

            // Upsert (Actualizar o Insertar)
            await BricksetCache.findOneAndUpdate(
                { number: cleanData.number }, // Condición de búsqueda
                { $set: cleanData },          // Nuevos datos
                { new: true, upsert: true }   // Insertar si no existe
            );

            // Devolvemos el ID del set (BFF)
            return cleanData.number; 
        } else {
            return null; // Código de barras no encontrado
        }

    } catch (error) {
        console.error(`Error en Brickset Service (getSetByBarcode - ${barcode}):`, error.message);
        throw error;
    }
};

//Obtiene las instrucciones de montaje de un set usando su ID
const getInstructions = async (setId) => {
    try {
        // Necesitamos el 'setID' interno de Brickset no el de Rebrickable
        let cachedSet = await BricksetCache.findOne({ number: setId });
        
        // Si por algún motivo no lo tenemos en caché, lo descargamos primero
        if (!cachedSet) {
            cachedSet = await getSetDetails(setId);
            // Si después de buscarlo en la API sigue sin existir, salimos
            if (!cachedSet) return [];
        }

        const internalSetID = cachedSet.setID; // Número entero que quiere Brickset

        // Llamada a la API de Brickset con el parámetro directo
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