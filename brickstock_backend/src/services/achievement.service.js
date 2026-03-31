const Achievement = require('../models/achievement.model');
const User = require('../models/user.model');

// 1. Semillero: Crea los logros base si no existen
const seedAchievements = async () => {
    try {
        const count = await Achievement.countDocuments();
        if (count === 0) {
            const initialAchievements = [
                { code: 'FIRST_SET', name: 'Primer Ladrillo', description: 'Has añadido tu primer set a la colección.', icon: 'exposure_plus_1', conditionType: 'COLLECTION_COUNT', conditionValue: 1 },
                { code: 'TEN_SETS', name: 'Coleccionista Novato', description: 'Has alcanzado los 10 sets. ¡Esto engancha!', icon: 'local_fire_department', conditionType: 'COLLECTION_COUNT', conditionValue: 10 },
                { code: 'FIFTY_SETS', name: 'Maestro Constructor', description: '50 sets en tu colección. Nivel experto.', icon: 'diamond', conditionType: 'COLLECTION_COUNT', conditionValue: 50 },
            ];
            await Achievement.insertMany(initialAchievements);
            console.log('🏁 Gamificación: Logros base insertados en MongoDB.');
        }
    } catch (err) {
        console.error('Error al poblar logros:', err);
    }
};

// 2. Evaluador: Se llama automáticamente cuando el usuario añade un set
const evaluateCollectionAchievements = async (userId, collectionCount) => {
    // Buscamos qué logros requieren X sets o menos
    const achievementsToUnlock = await Achievement.find({
        conditionType: 'COLLECTION_COUNT',
        conditionValue: { $lte: collectionCount }
    });

    if (achievementsToUnlock.length === 0) return null;

    const user = await User.findById(userId);
    let newlyUnlocked = [];

    // Comprobamos cuáles de esos logros NO tiene el usuario todavía
    achievementsToUnlock.forEach(achievement => {
        const alreadyHas = user.unlockedAchievements.some(
            ua => ua.achievement.toString() === achievement._id.toString()
        );
        if (!alreadyHas) {
            user.unlockedAchievements.push({ achievement: achievement._id });
            newlyUnlocked.push(achievement); // Lo guardamos para avisar a Flutter
        }
    });

    // Si ha ganado algo nuevo, guardamos el usuario actualizado
    if (newlyUnlocked.length > 0) {
        await user.save();
        return newlyUnlocked; 
    }

    return null;
};

// 3. Catálogo: Devuelve todos los logros e indica si el usuario los tiene
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

module.exports = { seedAchievements, evaluateCollectionAchievements, getUserAchievements };