const Collection = require('../models/collection.model');


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
        res.status(201).json({ success: true, message: 'Set añadido a la colección', data: newItem });

    } catch (error) {
        console.error("Error al añadir a colección:", error);
        res.status(500).json({ success: false, message: 'Error al añadir el set', error: error.message });
    }
};
// GET: Obtener toda la cartera del usuario
exports.getUserCollection = async (req, res) => {
    try {
        // Aquí haremos el Portfolio.find({ userId: req.user._id })
        res.status(200).json({ message: "Endpoint para ver cartera listo" });
    } catch (error) {
        res.status(500).json({ message: 'Error al obtener la cartera', error: error.message });
    }
};

// PUT y DELETE (Modificar cantidad o vender/borrar)
exports.updateCollectionItem = async (req, res) => { res.status(200).send("Actualizar set"); };
exports.deleteCollectionItem = async (req, res) => { res.status(200).send("Borrar set"); };