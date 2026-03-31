const Collection = require('../models/collection.model');
const rebrickableService = require('../services/rebrickable.service');
const achievementService = require('../services/achievement.service');

// POST: Añadir un nuevo set a la cartera
exports.addSetToCollection = async (req, res) => {
    try {
        const { setNum, quantity = 1, purchasePrice, condition = 'NISB' } = req.body;
        const userId = req.user.id; // Viene de nuestro middleware verifyJWT

        // 1. (Opcional pero recomendado) Comprobar si el set existe en Rebrickable 
        // y guardarlo en nuestra caché si tuviéramos un SetCache.model.
        // const setDetails = await rebrickableService.getSetByNum(setNum);

        // 2. Comprobar si el usuario ya tiene este set en su colección
        let existingItem = await Collection.findOne({ userId, setNum, condition });

        if (existingItem) {
            // Si ya lo tiene, actualizamos la cantidad
            existingItem.quantity += quantity;
            // Podrías hacer una media del precio de compra aquí
            await existingItem.save();
            return res.status(200).json({ success: true, message: 'Cantidad actualizada en la colección', data: existingItem });
        }

        // 3. Si no lo tiene, creamos un registro nuevo
        const newItem = new Collection({
            userId,
            setNum,
            quantity,
            purchasePrice,
            condition
        });

        await newItem.save();
        // === TFG: INTERCEPTOR DE GAMIFICACIÓN ===
        // Contamos cuántos sets tiene ahora en total
        const totalSets = await Collection.countDocuments({ userId: req.user.id });
        
        // Evaluamos si merece premio
        const newlyUnlocked = await achievementService.syncCollectionAchievements(req.user.id, totalSets);
        // =========================================

        res.status(201).json({
        success: true,
        message: 'Set añadido a la colección',
        data: newItem,
        newAchievements: newlyUnlocked // <-- ¡Enviamos el premio a Flutter en la misma petición!
        });

    } catch (error) {
        console.error("Error al añadir a colección:", error);
        res.status(500).json({ success: false, message: 'Error al añadir el set', error: error.message });
    }
};
// GET: Obtener toda la cartera del usuario
exports.getUserCollection = async (req, res) => {
    try {
        // 1. Buscamos la colección del usuario en MongoDB
        const collection = await Collection.find({ userId: req.user.id });

        // 2. Enriquecemos cada item con datos de Rebrickable (Patrón BFF)
        const enrichedCollection = await Promise.all(collection.map(async (item) => {
            let setDetails = {};
            try {
                // Llamamos a nuestra caché/servicio de Rebrickable.
                setDetails = await rebrickableService.getSetByNum(item.setNum); 
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
                numParts: setDetails.pieces || 0
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
        // Buscamos por ID de la colección Y por userId por seguridad (evita que un usuario borre items de otro)
        const deletedItem = await Collection.findOneAndDelete({ 
            _id: req.params.id, 
            userId: req.user.id 
        });

        if (!deletedItem) {
            return res.status(404).json({ success: false, message: 'Set no encontrado en tu colección' });
        }

        const totalSets = await Collection.countDocuments({ userId: req.user.id });
        await achievementService.syncCollectionAchievements(req.user.id, totalSets);

        res.status(200).json({ success: true, message: 'Set borrado de la colección' });
    } catch (error) {
        res.status(500).json({ success: false, message: 'Error al borrar', error: error.message });
    }
};

// PUT y DELETE (Modificar cantidad o vender/borrar)
exports.updateCollectionItem = async (req, res) => { res.status(200).send("Actualizar set"); };