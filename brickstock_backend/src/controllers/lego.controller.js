const axios = require('axios');
const rebrickableService = require('../services/rebrickable.service');
const bricksetService = require('../services/brickset.service'); // SERVICIO BRICKSET
const marketService = require('../services/market.service');

const getThemes = async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const search = req.query.search || '';
        const sort = req.query.sort || 'name_asc';

        const data = await rebrickableService.getThemes(page, search, sort);
        res.status(200).json(data);
    } catch (error) {
        res.status(500).json({ message: 'Error al obtener temas', error: error.message });
    }
};

const getSetsByTheme = async (req, res) => {
    try {
        const themeId = req.params.themeId; 
        const page = parseInt(req.query.page) || 1;
        const search = req.query.search || '';

        const data = await rebrickableService.getSetsByTheme(themeId, page, search);
        res.status(200).json(data);
    } catch (error) {
        res.status(500).json({ message: 'Error al obtener sets del tema', error: error.message });
    }
};

/*const getImageProxy = async (req, res) => {
    const { url } = req.query; 
    
    if (!url) {
        return res.status(400).send('Falta el parámetro url');
    }

    try {
        const response = await axios({
            url: url,
            method: 'GET',
            responseType: 'stream',
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'Accept': 'image/webp,image/apng,image/*,* QUITAR ESPACIO EN CASO DE USAR/*;q=0.8',
                'Accept-Encoding': 'gzip, deflate, br'
            }
        });

        res.setHeader('Access-Control-Allow-Origin', '*');
        res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
        res.setHeader('Content-Type', response.headers['content-type']);
        
        response.data.pipe(res);
    } catch (error) {
        console.error("Error proxy imagen:", error.message);
        res.status(404).send('Imagen no encontrada');
    }
};*/
const getImageProxy = async (req, res) => {
    const { url } = req.query; 
    
    if (!url) return res.status(400).send('Falta la URL');

    try {
        // Descargamos la imagen entera en memoria (arraybuffer) en lugar de stream
        const response = await axios.get(url, {
            responseType: 'arraybuffer',
            timeout: 8000, 
            headers: {
                // Cabeceras exactas de Google Chrome actual para saltar el Firewall
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
                'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
                'Accept-Language': 'es-ES,es;q=0.9,en;q=0.8',
                'Referer': 'https://rebrickable.com/',
                'Sec-Ch-Ua': '"Chromium";v="122", "Not(A:Brand";v="24", "Google Chrome";v="122"',
                'Sec-Ch-Ua-Mobile': '?0',
                'Sec-Ch-Ua-Platform': '"Windows"',
                'Sec-Fetch-Dest': 'image',
                'Sec-Fetch-Mode': 'no-cors',
                'Sec-Fetch-Site': 'cross-site'
            }
        });

        // Configuración de CORS manual para Flutter Web
        res.setHeader('Access-Control-Allow-Origin', '*');
        res.setHeader('Access-Control-Allow-Methods', 'GET');
        res.setHeader('Cache-Control', 'public, max-age=86400'); // Cache de 24h
        res.setHeader('Content-Type', response.headers['content-type']);
        
        // Enviamos el buffer de memoria directamente
        res.send(response.data);
    } catch (error) {
        console.error("❌ Fallo en Proxy de Imagen Rebrickable:", error.message);
        res.redirect('https://via.placeholder.com/300x200?text=Imagen+No+Disponible');
    }
};

const getThemeCover = async (req, res) => {
    try {
        const { themeId } = req.params;
        const imageUrl = await rebrickableService.getThemeCover(themeId);
        
        res.status(200).json({ url: imageUrl });
    } catch (error) {
        res.status(200).json({ url: null });
    }
};

const getSetMinifigs = async (req, res) => {
  try {
    const { set_num } = req.params;
    const minifigs = await rebrickableService.getSetMinifigs(set_num);
    
    res.json({
      success: true,
      count: minifigs.length,
      data: minifigs
    });
  } catch (error) {
    res.status(500).json({ 
      success: false, 
      message: 'Error al obtener las minifiguras del set' 
    });
  }
};
const getMinifigSets = async (req, res) => {
  try {
    const { fig_num } = req.params;
    const sets = await rebrickableService.getMinifigSets(fig_num);
    
    res.json({
      success: true,
      count: sets.length,
      data: sets
    });
  } catch (error) {
    res.status(500).json({ 
      success: false, 
      message: 'Error al obtener los sets de la minifigura' 
    });
  }
};
const getAllSets = async (req, res) => {
    try {
        const { page = 1, search = '' } = req.query;
        const data = await rebrickableService.getAllSets(page, search);
        res.json(data);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// GET: Buscar todas las minifiguras (Paginado)
const getMinifigs = async (req, res) => {
    try {
        const page = req.query.page || 1;
        const search = req.query.search || '';

        const data = await rebrickableService.getAllMinifigs(page, search);
        res.status(200).json({ success: true, data });
    } catch (error) {
        console.error("Error obteniendo minifiguras:", error);
        res.status(500).json({ success: false, message: 'Error al obtener minifiguras', error: error.message });
    }
};

// GET: Detalles de una minifigura y en qué sets aparece
const getMinifigDetails = async (req, res) => {
    try {
        const { figNum } = req.params;

        // Ejecutamos ambas peticiones a Rebrickable en paralelo para reducir el tiempo de respuesta (Latencia)
        const [details, sets] = await Promise.all([
            rebrickableService.getMinifigDetails(figNum),
            rebrickableService.getMinifigSets(figNum)
        ]);

        res.status(200).json({ 
            success: true, 
            data: {
                ...details,
                appearsInSets: sets // Inyectamos los sets en la misma respuesta
            } 
        });
    } catch (error) {
        console.error(`Error obteniendo detalles de la minifigura ${req.params.figNum}:`, error);
        res.status(500).json({ success: false, message: 'Error al obtener detalles', error: error.message });
    }
};

/*const getSetMarketData = async (req, res) => {
    try {
        const { setId } = req.params;
        
        // Usamos getSetByNum, que es como se llama en tu servicio
        const setDetails = await rebrickableService.getSetByNum(setId);
        
        // Le pasamos setDetails.pieces en lugar de num_parts
        const marketData = marketService.generateMockMarketData(
            setId, 
            setDetails.pieces, 
            setDetails.year
        );

        res.status(200).json(marketData);
    } catch (error) {
        console.error(`Error al obtener mercado para ${req.params.setId}:`, error.message);
        res.status(500).json({ message: 'Error al calcular datos de mercado' });
    }
};*/
const getSetMarketData = async (req, res) => {
    try {
        const { setId } = req.params;
        
        // 1. Llamada en paralelo: Rebrickable (piezas/año) + Brickset (precio/estado)
        const [setDetails, bricksetData] = await Promise.all([
            rebrickableService.getSetByNum(setId),
            bricksetService.getSetDetails(setId).catch(() => null) // Si Brickset falla, no rompe la app
        ]);

        if (!setDetails) {
            return res.status(404).json({ message: 'Set no encontrado en Rebrickable' });
        }

        // 2. Extraer precios reales
        let rrp = null;
        let availability = null;
        let exitDate = null;

        if (bricksetData) {
            availability = bricksetData.availability;
            exitDate = bricksetData.exitDate;

            if (bricksetData.LEGOCom) {
                // Como es un Map de Mongoose, debemos usar .get('DE') en lugar de .DE
                const deData = bricksetData.LEGOCom.get ? bricksetData.LEGOCom.get('DE') : bricksetData.LEGOCom.DE;
                const usData = bricksetData.LEGOCom.get ? bricksetData.LEGOCom.get('US') : bricksetData.LEGOCom.US;

                if (deData) {
                    rrp = deData.retailPrice;
                } else if (usData) {
                    rrp = usData.retailPrice;
                }
            }
        }

        // 3. Generar mercado inyectando la pura verdad
        const marketData = marketService.generateMockMarketData(
            setId, 
            setDetails.pieces, 
            setDetails.year,
            rrp,
            availability,
            exitDate
        );

        res.status(200).json(marketData);
    } catch (error) {
        console.error(`Error al obtener mercado para ${req.params.setId}:`, error.message);
        res.status(500).json({ message: 'Error al calcular datos de mercado' });
    }
};

const scanBarcode = async (req, res) => {
    try {
        const { barcode } = req.params;

        // 1. Buscar el código en Brickset
        const setId = await bricksetService.getSetByBarcode(barcode);

        if (!setId) {
            return res.status(404).json({ message: 'No se ha encontrado ningún set con este código' });
        }

        // 2. Obtener datos combinados (Si falla Rebrickable, evitamos que rompa)
        const [setDetails, bricksetData] = await Promise.all([
            rebrickableService.getSetByNum(setId).catch(() => null),
            bricksetService.getSetDetails(setId).catch(() => null)
        ]);

        if (!setDetails) {
            return res.status(404).json({ message: 'Set encontrado por código, pero sin datos visuales en Rebrickable' });
        }

        // 3. Extraer precios y fechas
        let rrp = null;
        let availability = null;
        let exitDate = null;

        if (bricksetData) {
            availability = bricksetData.availability;
            exitDate = bricksetData.exitDate;

            if (bricksetData.LEGOCom) {
                const deData = bricksetData.LEGOCom.get ? bricksetData.LEGOCom.get('DE') : bricksetData.LEGOCom.DE;
                const usData = bricksetData.LEGOCom.get ? bricksetData.LEGOCom.get('US') : bricksetData.LEGOCom.US;
                if (deData) rrp = deData.retailPrice;
                else if (usData) rrp = usData.retailPrice;
            }
        }

        // 4. NORMALIZACIÓN DE DATOS
        // Desempaquetamos por si tu servicio de Rebrickable los mete dentro de un "data: {}"
        const actualSet = setDetails.data ? setDetails.data : setDetails;
        
        const safeImgUrl = actualSet.set_img_url || actualSet.imgUrl || actualSet.image || '';
        // Buscamos las piezas y el año sea cual sea el nombre que tengan en tu servicio
        const safePieces = actualSet.num_parts || actualSet.pieces || 0;
        const safeYear = actualSet.year || actualSet.año || new Date().getFullYear();

        const marketData = marketService.generateMockMarketData(
            setId,
            safePieces,
            safeYear,
            rrp,
            availability,
            exitDate
        );

        // 5. CONSTRUIR EL JSON BLINDADO PARA FLUTTER
        const responseData = {
            // Forzamos los nombres exactos que espera LegoSet.fromJson
            set_num: actualSet.set_num || actualSet.id || setId,
            name: actualSet.name || actualSet.nombre || 'Desconocido',
            year: safeYear,
            theme_id: actualSet.theme_id || actualSet.themeId || 0,
            num_parts: safePieces,
            set_img_url: safeImgUrl,

            //Aseguramos que el factory lo pilla
            imgUrl: safeImgUrl,   
            imageUrl: safeImgUrl,
            
            // Nuestros datos inyectados de Brickset
            officialRrp: rrp,
            availability: availability,
            marketData: marketData
        };

        res.status(200).json(responseData);
    } catch (error) {
        console.error('Error en scanBarcode:', error.message);
        res.status(500).json({ message: 'Error al escanear el código de barras' });
    }
};

const getThemeById = async (req, res) => {
    try {
        const theme = await rebrickableService.getThemeById(req.params.id);
        res.status(200).json({ success: true, data: theme });
    } catch (error) {
        res.status(500).json({ message: 'Error al obtener tema' });
    }
};


module.exports = {
    getThemes,
    getSetsByTheme,
    getImageProxy,
    getThemeCover,
    getSetMinifigs,
    getMinifigSets,
    getAllSets,
    getMinifigs,
    getMinifigDetails,
    getSetMarketData,
    scanBarcode,
    getThemeById
};