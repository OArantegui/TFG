const axios = require('axios');
const rebrickableService = require('../services/rebrickable.service');
const bricksetService = require('../services/brickset.service');
const marketService = require('../services/market.service');

const getThemes = async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const search = req.query.search || '';
        const sort = req.query.sort || 'id_desc';

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

const getImageProxy = async (req, res) => {
    const { url } = req.query; 
    
    if (!url) return res.status(400).send('Falta la URL');

    try {
        // Descargamos la imagen entera en memoria
        const response = await axios.get(url, {
            responseType: 'arraybuffer',
            timeout: 8000, 
            headers: {
                // Cabeceras exactas de Google Chrome para saltar el Firewall
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

        //Buscamos los sets en los que sale a la vez
        const [details, sets] = await Promise.all([
            rebrickableService.getMinifigDetails(figNum),
            rebrickableService.getMinifigSets(figNum)
        ]);

        res.status(200).json({ 
            success: true, 
            data: {
                ...details,
                appearsInSets: sets
            } 
        });
    } catch (error) {
        console.error(`Error obteniendo detalles de la minifigura ${req.params.figNum}:`, error);
        res.status(500).json({ success: false, message: 'Error al obtener detalles', error: error.message });
    }
};

const getSetMarketData = async (req, res) => {
    try {
        const { setId } = req.params;
        
        //Llamada en paralelo a ambas apis
        const [setDetails, bricksetData] = await Promise.all([
            rebrickableService.getSetByNum(setId),
            bricksetService.getSetDetails(setId).catch(() => null)
        ]);

        if (!setDetails) {
            return res.status(404).json({ message: 'Set no encontrado en Rebrickable' });
        }

        //Extraer precios reales y Fechas
        let rrp = null;
        let availability = null;
        let exitDate = null;
        let launchDate = null; 

        if (bricksetData) {
            availability = bricksetData.availability;
            exitDate = bricksetData.exitDate;
            launchDate = bricksetData.launchDate; // Extraemos la fecha de salida

            if (bricksetData.LEGOCom) {
                const deData = bricksetData.LEGOCom.get ? bricksetData.LEGOCom.get('DE') : bricksetData.LEGOCom.DE;
                const usData = bricksetData.LEGOCom.get ? bricksetData.LEGOCom.get('US') : bricksetData.LEGOCom.US;

                if (deData) {
                    rrp = deData.retailPrice;
                } else if (usData) {
                    rrp = usData.retailPrice;
                }
            }
        }

        //Generar mercado inyectando precio real y fechas completas
        const marketData = marketService.generateMockMarketData(
            setId, 
            setDetails.pieces, 
            setDetails.year,
            rrp,
            availability,
            exitDate,
            launchDate
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

        //Buscar el código en Brickset
        const setId = await bricksetService.getSetByBarcode(barcode);

        if (!setId) {
            return res.status(404).json({ message: 'No se ha encontrado ningún set con este código' });
        }

        //Obtener datos combinados
        const [setDetails, bricksetData] = await Promise.all([
            rebrickableService.getSetByNum(setId).catch(() => null),
            bricksetService.getSetDetails(setId).catch(() => null)
        ]);

        if (!setDetails) {
            return res.status(404).json({ message: 'Set encontrado por código, pero sin datos visuales en Rebrickable' });
        }
        
        //Extraer precios y fechas
        let rrp = null;
        let availability = null;
        let exitDate = null;
        let launchDate = null; 

        if (bricksetData) {
            availability = bricksetData.availability;
            exitDate = bricksetData.exitDate;
            launchDate = bricksetData.launchDate; 

            if (bricksetData.LEGOCom) {
                const deData = bricksetData.LEGOCom.get ? bricksetData.LEGOCom.get('DE') : bricksetData.LEGOCom.DE;
                const usData = bricksetData.LEGOCom.get ? bricksetData.LEGOCom.get('US') : bricksetData.LEGOCom.US;
                if (deData) rrp = deData.retailPrice;
                else if (usData) rrp = usData.retailPrice;
            }
        }

        const actualSet = setDetails.data ? setDetails.data : setDetails;
        //Prevenimos fallos en nombres de campos poniendo distintas opciones
        const safeImgUrl = actualSet.set_img_url || actualSet.imageUrl || actualSet.imgUrl || actualSet.image || '';       
        
        const safePieces = actualSet.num_parts || actualSet.pieces || 0;
        const safeYear = actualSet.year || actualSet.año || new Date().getFullYear();

        const marketData = marketService.generateMockMarketData(
            setId,
            safePieces,
            safeYear,
            rrp,
            availability,
            exitDate,
            launchDate 
        );

        //Json combinando los datos de ambas apis
        const responseData = {
            // Forzamos los nombres exactos que espera LegoSet.fromJson
            set_num: actualSet.set_num || actualSet._id || actualSet.id || setId,
            name: actualSet.name || actualSet.nombre || 'Desconocido',
            year: safeYear,
            theme_id: actualSet.theme_id || actualSet.themeId || 0,
            num_parts: safePieces,
            set_img_url: safeImgUrl,
            
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

// GET: Obtener el tema de un set para los detalles
const getThemeById = async (req, res) => {
    try {
        const theme = await rebrickableService.getThemeById(req.params.id);
        res.status(200).json({ success: true, data: theme });
    } catch (error) {
        res.status(500).json({ message: 'Error al obtener tema' });
    }
};

// GET: Obtener la lista de pdfs de instrucciones
const getSetInstructions = async (req, res) => {
    try {
        const { setId } = req.params;
        const instructions = await bricksetService.getInstructions(setId);

        // Filtramos y extraemos solo las URLs de los manuales (core.pdf)
        const validUrls = instructions
            .filter(inst => inst.URL.includes('core.pdf'))
            .map(inst => inst.URL);

        // Eliminamos posibles duplicados exactos
        const uniqueUrls = [...new Set(validUrls)];

        res.status(200).json({ success: true, urls: uniqueUrls });
    } catch (error) {
        console.error(`Error al obtener instrucciones para ${req.params.setId}:`, error.message);
        res.status(500).json({ success: false, message: 'Error al obtener instrucciones' });
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
    getThemeById,
    getSetInstructions
};