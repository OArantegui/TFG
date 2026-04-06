const Wishlist = require('../models/wishlist.model');
const User = require('../models/user.model');
const rebrickableService = require('../services/rebrickable.service');

// AÑADIR A LA LISTA CON VALIDACIÓN DE PRESUPUESTO
exports.addToWishlist = async (req, res) => {
    try {
        const { setNum, price, force = false } = req.body;
        const userId = req.user.id;

        const existing = await Wishlist.findOne({ userId, setNum });
        if (existing) {
            return res.status(400).json({ success: false, message: 'El set ya está en tus deseados' });
        }

        const user = await User.findById(userId);
        const budget = user.wishlistBudget || 500;

        // Calculamos el valor actual de toda la lista
        const list = await Wishlist.find({ userId });
        const currentTotal = list.reduce((sum, item) => sum + (item.targetPrice || 0), 0);

        // Si supera el límite y NO hemos forzado el guardado, devolvemos un warning
        if (!force && (currentTotal + price) > budget) {
            return res.status(200).json({ 
                success: false, 
                warning: true, 
                message: `Añadir este set elevaría tu lista a ${(currentTotal + price).toFixed(2)}€, superando tu límite de ${budget}€.`
            });
        }

        const newItem = new Wishlist({ userId, setNum, targetPrice: price });
        await newItem.save();
        res.status(201).json({ success: true, message: 'Set añadido a deseados' });

    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

// OBTENER LA LISTA Y EL PRESUPUESTO
exports.getUserWishlist = async (req, res) => {
    try {
        const user = await User.findById(req.user.id);
        const list = await Wishlist.find({ userId: req.user.id });

        const enrichedList = await Promise.all(list.map(async (item) => {
            let setDetails = {};
            try {
                setDetails = await rebrickableService.getSetByNum(item.setNum); 
            } catch (err) {}

            return {
                id: item._id, 
                setNum: item.setNum,
                targetPrice: item.targetPrice,
                name: setDetails.name || 'Set Desconocido',
                imgUrl: setDetails.imageUrl || 'https://via.placeholder.com/150',
                numParts: setDetails.pieces || 0,
                year: setDetails.year || 0,
                themeId: setDetails.theme_id || 0
            };
        }));

        res.status(200).json({ 
            success: true, 
            budget: user.wishlistBudget || 500,
            data: enrichedList 
        });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

// ACTUALIZAR PRESUPUESTO
exports.updateBudget = async (req, res) => {
    try {
        const { newBudget } = req.body;
        await User.findByIdAndUpdate(req.user.id, { wishlistBudget: newBudget });
        res.status(200).json({ success: true, message: 'Presupuesto actualizado' });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

// BORRAR SET
exports.deleteFromWishlist = async (req, res) => {
    try {
        await Wishlist.findOneAndDelete({ _id: req.params.id, userId: req.user.id });
        res.status(200).json({ success: true, message: 'Set borrado' });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};