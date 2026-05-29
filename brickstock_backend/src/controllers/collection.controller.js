const Collection = require('../models/collection.model');
const MinifigCollection = require('../models/minifig_collection.model');
const rebrickableService = require('../services/rebrickable.service');
const achievementService = require('../services/achievement.service');
const marketService = require('../services/market.service');
const bricksetService = require('../services/brickset.service');


// POST: Añadir un nuevo set a la coleccion
exports.addSetToCollection = async (req, res) => {
    try {
        const { setNum, quantity = 1, purchasePrice } = req.body;
        const userId = req.user.id; 

        // Comprobar si existe el set en la colección
        let existingItem = await Collection.findOne({ userId, setNum });

        if (existingItem) {
            existingItem.quantity += quantity;
            await existingItem.save();
            return res.status(200).json({ success: true, message: 'Cantidad actualizada en la colección', data: existingItem });
        }

        let cacheData = { pieces: 0, year: new Date().getFullYear(), rrp: null, launchDate: null, exitDate: null, themeId: null, rootThemeId: null };
        try {
            const [setDetails, bricksetData] = await Promise.all([
                rebrickableService.getSetByNum(setNum).catch(() => null),
                bricksetService.getSetDetails(setNum).catch(() => null)
            ]);

            if (setDetails) {
                cacheData.pieces = setDetails.pieces || setDetails.num_parts || 0;
                cacheData.year = setDetails.year || new Date().getFullYear();
                const rawThemeId = setDetails.themeId || setDetails.theme_id || null;
                cacheData.themeId = rawThemeId;
                
                if (rawThemeId) {
                    // Calculamos el tema raíz para la gamificación
                    cacheData.rootThemeId = await rebrickableService.getRootThemeId(rawThemeId);
                }
            }
            if (bricksetData) {
                cacheData.launchDate = bricksetData.launchDate;
                cacheData.exitDate = bricksetData.exitDate;
                if (bricksetData.LEGOCom) {
                    const deData = bricksetData.LEGOCom.get ? bricksetData.LEGOCom.get('DE') : bricksetData.LEGOCom.DE;
                    const usData = bricksetData.LEGOCom.get ? bricksetData.LEGOCom.get('US') : bricksetData.LEGOCom.US;
                    if (deData) cacheData.rrp = deData.retailPrice;
                    else if (usData) cacheData.rrp = usData.retailPrice;
                }
            }
        } catch (err) {
            console.error("Error obteniendo datos para caché de mercado:", err.message);
        }

        //Crear el nuevo registro del Set
        const newItem = new Collection({ userId, setNum, quantity, purchasePrice, marketDataCache: cacheData });
        await newItem.save();

        // Se añaden las minifiguras del set
        try {
            const minifigs = await rebrickableService.getSetMinifigs(setNum);
            
            if (minifigs && minifigs.length > 0) {
                for (const fig of minifigs) {
                    // Verificamos si el usuario ya tiene esta minifigura
                    let existingFig = await MinifigCollection.findOne({ userId, figNum: fig.figNum });
                    
                    // Calculamos cuántas minifiguras reales trae (cantidad en el set * cantidad de sets comprados)
                    const figsToAdd = (fig.quantity || 1) * quantity;

                    if (existingFig) {
                        existingFig.quantity += figsToAdd;
                        await existingFig.save();
                    } else {
                        await MinifigCollection.create({
                            userId,
                            figNum: fig.figNum,
                            quantity: figsToAdd,
                            source: 'From Set',
                            sourceSetNum: setNum
                        });
                    }
                }
            }
        } catch (figError) {
            // Capturamos el error pero NO paramos la ejecución, porque el Set ya se ha guardado
            console.error("Error al añadir minifiguras del set:", figError.message);
        }

        // Comprobamos insignias
        const totalSets = await Collection.countDocuments({ userId });
        const newlyUnlocked = await achievementService.syncCollectionAchievements(userId);

        res.status(201).json({
            success: true,
            message: 'Set y sus minifiguras añadidos a la colección',
            data: newItem,
            newAchievements: newlyUnlocked 
        });

    } catch (error) {
        console.error("Error al añadir a colección:", error);
        res.status(500).json({ success: false, message: 'Error al añadir el set', error: error.message });
    }
};

// GET: Obtener toda la coleccion del usuario
exports.getUserCollection = async (req, res) => {
    try {
        //Buscamos la colección del usuario en MongoDB
        const collection = await Collection.find({ userId: req.user.id });

        //Enriquecemos cada item con datos
        const enrichedCollection = await Promise.all(collection.map(async (item) => {
            let setDetails = {};
            let themeName = 'Desconocido';
            try {
                //Servicio API Rebrickable
                setDetails = await rebrickableService.getSetByNum(item.setNum); 
                
                //Nombre del tema
                const themeId = setDetails.theme_id || setDetails.themeId;
                if (themeId) {
                    const themeData = await rebrickableService.getThemeById(themeId);
                    themeName = themeData.name || 'Desconocido';
                }
            } catch (err) {
                console.error(`Error obteniendo detalles del set ${item.setNum}`);
            }

            return {
                id: item._id, 
                setNum: item.setNum,
                quantity: item.quantity,
                purchasePrice: item.purchasePrice,
                currentPrice: item.purchasePrice, 
                name: setDetails.name || 'Set Desconocido',
                imgUrl: setDetails.imageUrl || 'https://via.placeholder.com/150',
                numParts: setDetails.pieces || 0,
                year: setDetails.year || 0,
                themeId: setDetails.themeId || setDetails.theme_id || 0,
                themeName: themeName
            };
        }));

        res.status(200).json({ success: true, data: enrichedCollection });
    } catch (error) {
        res.status(500).json({ success: false, message: 'Error al obtener la cartera', error: error.message });
    }
};

// DELETE: Borrar set de la colección
exports.deleteCollectionItem = async (req, res) => {
    try {
        //Buscamos set de la colección principal
        const deletedItem = await Collection.findOneAndDelete({ 
            _id: req.params.id, 
            userId: req.user.id 
        });

        if (!deletedItem) {
            return res.status(404).json({ success: false, message: 'Set no encontrado en tu colección' });
        }

        //Borramos las figuras del set
        try {
            const minifigs = await rebrickableService.getSetMinifigs(deletedItem.setNum);
            
            if (minifigs && minifigs.length > 0) {
                for (const fig of minifigs) {
                    let existingFig = await MinifigCollection.findOne({ userId: req.user.id, figNum: fig.figNum });
                    
                    if (existingFig) {
                        // Calculamos cuántas hay que restar (las que trae el set * la cantidad de sets que borramos)
                        const figsToRemove = (fig.quantity || 1) * deletedItem.quantity;
                        
                        existingFig.quantity -= figsToRemove;

                        //Solo le quitamos las que trae el set
                        if (existingFig.quantity <= 0) {
                            await MinifigCollection.findByIdAndDelete(existingFig._id);
                        } else {
                            await existingFig.save();
                        }
                    }
                }
            }
        } catch (figError) {
            console.error("Error al auto-eliminar minifiguras del set:", figError.message);
        }

        //Sincronizamos los logros por si ha bajado de nivel
        const totalSets = await Collection.countDocuments({ userId: req.user.id });
        await achievementService.syncCollectionAchievements(req.user.id);

        res.status(200).json({ success: true, message: 'Set y sus minifiguras asociados borrados de la colección' });
    } catch (error) {
        console.error("Error al borrar el set:", error);
        res.status(500).json({ success: false, message: 'Error al borrar', error: error.message });
    }
};

// Actualizar
exports.updateCollectionItem = async (req, res) => { res.status(200).send("Actualizar set"); };

// GET: Obtener la colección de minifiguras del usuario
exports.getUserMinifigCollection = async (req, res) => {
    try {
        const collection = await MinifigCollection.find({ userId: req.user.id });

        //Enriquecemos con datos de API
        const enrichedCollection = await Promise.all(collection.map(async (item) => {
            let details = {};
            try {
                details = await rebrickableService.getMinifigDetails(item.figNum);
            } catch (err) {
                console.error(`Error obteniendo detalles de minifig ${item.figNum}`);
            }

            return {
                id: item._id,
                figNum: item.figNum,
                quantity: item.quantity,
                source: item.source,
                sourceSetNum: item.sourceSetNum,
                name: details.name || 'Minifigura Desconocida',
                numParts: details.num_parts || 0,
                imageUrl: details.set_img_url || 'https://via.placeholder.com/150'
            };
        }));

        res.status(200).json({ success: true, data: enrichedCollection });
    } catch (error) {
        console.error("Error al obtener la colección de minifiguras:", error);
        res.status(500).json({ success: false, message: 'Error al obtener la cartera de minifiguras', error: error.message });
    }
};

// POST: Añadir una minifigura suelta manualmente
exports.addMinifigToCollection = async (req, res) => {
    try {
        const { figNum, quantity = 1 } = req.body;
        const userId = req.user.id;

        let existingItem = await MinifigCollection.findOne({ userId, figNum });

        if (existingItem) {
            existingItem.quantity += quantity;
            await existingItem.save();
            return res.status(200).json({ success: true, message: 'Cantidad actualizada', data: existingItem });
        }

        const newItem = new MinifigCollection({
            userId,
            figNum,
            quantity,
            source: 'Manual' //No viene de un set, se añade manual
        });

        await newItem.save();

        res.status(201).json({ success: true, message: 'Minifigura añadida a la colección', data: newItem });
    } catch (error) {
        console.error("Error al añadir minifigura a colección:", error);
        res.status(500).json({ success: false, message: 'Error al añadir minifigura', error: error.message });
    }
};
exports.removeMinifigFromCollection = async (req, res) => {
    try {
        const { id } = req.params; // ID de MongoDB de la minifigura
        const deletedItem = await MinifigCollection.findOneAndDelete({ _id: id, userId: req.user.id });
        
        if (!deletedItem) {
            return res.status(404).json({ success: false, message: 'Minifigura no encontrada' });
        }
        res.status(200).json({ success: true, message: 'Minifigura eliminada de la cartera' });
    } catch (error) {
        console.error("Error al eliminar minifigura:", error);
        res.status(500).json({ success: false, message: 'Error al eliminar', error: error.message });
    }
};

// GET: Obtener los datos de mercado agregados de toda la colección
exports.getCollectionMarketData = async (req, res) => {
    try {
        const userId = req.user.id; 
        
        const collectionItems = await Collection.find({ userId: userId });

        if (!collectionItems || collectionItems.length === 0) {
            return res.status(200).json({
                totalRetailPrice: 0,
                currentMarketValue: 0,
                history: []
            });
        }

        let totalRetail = 0;
        let totalMarket = 0;
        const historyMap = {};

        // Recorremos cada set de la colección usando nuestra base de datos
        collectionItems.forEach((item) => {
            try {
                // Recuperamos la caché
                const cache = item.marketDataCache || {};

                // Generamos su curva de mercado individual
                const marketData = marketService.generateMockMarketData(
                    item.setNum,
                    cache.pieces || 0,
                    cache.year || new Date().getFullYear(),
                    cache.rrp, 
                    null, // availability no hace falta con exitDate
                    cache.exitDate, 
                    cache.launchDate 
                );

                const qty = item.quantity || 1; 

                // Sumamos a los totales globales
                totalRetail += (marketData.estimatedRetailPrice * qty);
                totalMarket += (marketData.currentMarketValue * qty);

                // Sumamos cada mes a la gráfica global
                marketData.history.forEach(point => {
                    if (!historyMap[point.month]) {
                        historyMap[point.month] = 0;
                    }
                    historyMap[point.month] += (point.price * qty);
                });
            } catch (error) {
                console.error(`Error calculando mercado global para ${item.setNum}:`, error.message);
            }
        }); 

        // Convertimos el diccionario de meses en un array ordenado
        const historyArray = Object.keys(historyMap).map(month => ({
            month: month,
            price: parseFloat(historyMap[month].toFixed(2))
        })).sort((a, b) => a.month.localeCompare(b.month)); 

        res.status(200).json({
            totalRetailPrice: parseFloat(totalRetail.toFixed(2)),
            currentMarketValue: parseFloat(totalMarket.toFixed(2)),
            history: historyArray
        });

    } catch (error) {
        console.error('Error en getCollectionMarketData:', error);
        res.status(500).json({ message: 'Error al calcular mercado de la colección' });
    }
};