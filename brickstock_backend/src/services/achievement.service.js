const mongoose = require('mongoose');
const Achievement = require('../models/achievement.model');
const User = require('../models/user.model');
const Collection = require('../models/collection.model');
const MinifigCollection = require('../models/minifig_collection.model');

// Semillero: Crea los logros base si no existen
const seedAchievements = async () => {
    try {
        const count = await Achievement.countDocuments();
        if (count === 0) {
            const initialAchievements = [
                // Cantidad de Sets
                { code: 'FIRST_SET', name: 'Primer Ladrillo', description: 'Has añadido tu primer set a la colección.', icon: 'exposure_plus_1', conditionType: 'COLLECTION_COUNT', conditionValue: 1 },
                { code: 'TEN_SETS', name: 'Coleccionista Novato', description: 'Has alcanzado los 10 sets. ¡Esto engancha!', icon: 'local_fire_department', conditionType: 'COLLECTION_COUNT', conditionValue: 10 },
                { code: 'FIFTY_SETS', name: 'Maestro Constructor', description: '50 sets en tu colección. Nivel experto.', icon: 'diamond', conditionType: 'COLLECTION_COUNT', conditionValue: 50 },
                
                // Minifiguras
                { code: 'MINIFIG_10', name: 'Pueblo Ladrillo', description: 'Tu colección empieza a cobrar vida. Tienes 10 minifiguras.', icon: 'people', conditionType: 'MINIFIG_COUNT', conditionValue: 10 },
                { code: 'MINIFIG_100', name: 'Alcalde de Minifigville', description: '100 minifiguras. Empiezas a necesitar un censo oficial.', icon: 'groups', conditionType: 'MINIFIG_COUNT', conditionValue: 100 },
                { code: 'MINIFIG_500', name: 'Ejército de Plástico', description: '500 minifiguras. Tienes más habitantes que algunos pueblos reales.', icon: 'public', conditionType: 'MINIFIG_COUNT', conditionValue: 500 },
                
                // Valor de Inversión
                { code: 'VALUE_100', name: 'Primeros Dividendos', description: 'Has superado tus primeros 100€ de inversión. ¡A por más!', icon: 'savings', conditionType: 'TOTAL_VALUE', conditionValue: 100 },
                { code: 'VALUE_1000', name: 'El Lobo de Wall Brick', description: 'Una cartera de 1.000€. Ya juegas en las grandes ligas.', icon: 'trending_up', conditionType: 'TOTAL_VALUE', conditionValue: 1000 },
                { code: 'VALUE_5000', name: 'Magnate del ladrillo', description: '5.000€ en LEGO. Tu colección vale su peso en oro (o en plástico).', icon: 'account_balance', conditionType: 'TOTAL_VALUE', conditionValue: 5000 },

                // Monotemático (Max sets en 1 solo tema)
                { code: 'THEME_5', name: 'Fidelidad a la Marca', description: 'Tienes 5 sets del mismo tema. Un buen comienzo temático.', icon: 'category', conditionType: 'THEME_COUNT', conditionValue: 5 },
                { code: 'THEME_10', name: 'Curador Temático', description: '10 sets del mismo tema. Podrías abrir tu propia exposición.', icon: 'museum', conditionType: 'THEME_COUNT', conditionValue: 10 },
                { code: 'THEME_25', name: 'Obsesión Monotemática', description: '25 sets del mismo tema. Eres la máxima autoridad en este universo.', icon: 'workspace_premium', conditionType: 'THEME_COUNT', conditionValue: 25 },
            ];
            await Achievement.insertMany(initialAchievements);
            console.log('Logros base insertados en MongoDB.');
        }
    } catch (err) {
        console.error('Error al poblar logros:', err);
    }
};

// Comprobador: Evaluamos toda la cuenta del usuario
const syncCollectionAchievements = async (userId) => {
    try {
        const user = await User.findById(userId);
        if (!user) return [];

        const userObjId = new mongoose.Types.ObjectId(userId);

        // 1. Calcular Total de Sets
        const totalSets = await Collection.countDocuments({ userId: userObjId });

        // 2. Calcular Total de Minifiguras usando Agregación
        const minifigsAgg = await MinifigCollection.aggregate([
            { $match: { userId: userObjId } },
            { $group: { _id: null, total: { $sum: "$quantity" } } }
        ]);
        const totalMinifigs = minifigsAgg.length > 0 ? minifigsAgg[0].total : 0;

        // 3. Calcular Inversión Total (Precio Compra * Cantidad)
        const valueAgg = await Collection.aggregate([
            { $match: { userId: userObjId } },
            { $group: { _id: null, totalValue: { $sum: { $multiply: ["$purchasePrice", "$quantity"] } } } }
        ]);
        const totalValue = valueAgg.length > 0 ? valueAgg[0].totalValue : 0;

        // 4. Calcular máximo de sets en un solo tema
        const themeAgg = await Collection.aggregate([
            { $match: { userId: userObjId, "marketDataCache.rootThemeId": { $ne: null } } },
            { $group: { _id: "$marketDataCache.rootThemeId", count: { $sum: "$quantity" } } },
            { $sort: { count: -1 } },
            { $limit: 1 }
        ]);
        const maxThemeSets = themeAgg.length > 0 ? themeAgg[0].count : 0;

        // Recuperar todos los logros de la BBDD
        const allAchievements = await Achievement.find();
        let newlyUnlocked = [];
        let changed = false;

        allAchievements.forEach(ach => {
            const hasAchievementIndex = user.unlockedAchievements.findIndex(
                ua => ua.achievement.toString() === ach._id.toString()
            );
            
            // Decidir qué métrica mirar según el tipo de logro
            let metricToCompare = 0;
            switch(ach.conditionType) {
                case 'COLLECTION_COUNT': metricToCompare = totalSets; break;
                case 'MINIFIG_COUNT': metricToCompare = totalMinifigs; break;
                case 'TOTAL_VALUE': metricToCompare = totalValue; break;
                case 'THEME_COUNT': metricToCompare = maxThemeSets; break;
            }

            const qualifies = metricToCompare >= ach.conditionValue;

            if (qualifies && hasAchievementIndex === -1) {
                user.unlockedAchievements.push({ achievement: ach._id });
                newlyUnlocked.push(ach);
                changed = true;
            } else if (!qualifies && hasAchievementIndex !== -1) {
                user.unlockedAchievements.splice(hasAchievementIndex, 1);
                changed = true;
            }
        });

        if (changed) {
            await user.save();
        }
        return newlyUnlocked;
    } catch (error) {
        console.error('Error sincronizando logros:', error);
        return [];
    }
};

const getUserAchievements = async (userId) => {
    const allAchievements = await Achievement.find();
    const user = await User.findById(userId).populate('unlockedAchievements.achievement');
    return allAchievements.map(ach => {
        const unlockedData = user.unlockedAchievements.find(
            ua => ua.achievement && ua.achievement._id.toString() === ach._id.toString()
        );
        return {
            id: ach._id,
            name: ach.name,
            description: ach.description,
            icon: ach.icon,
            isUnlocked: !!unlockedData,
            unlockedAt: unlockedData ? unlockedData.unlockedAt : null
        };
    });
};

module.exports = { seedAchievements, syncCollectionAchievements, getUserAchievements };