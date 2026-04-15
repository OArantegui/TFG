const Achievement = require('../models/achievement.model');
const User = require('../models/user.model');

// Semillero: Crea los logros base si no existen
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
            console.log('Logros base insertados en MongoDB.');
        }
    } catch (err) {
        console.error('Error al poblar logros:', err);
    }
};

//Comprobador
const syncCollectionAchievements = async (userId, collectionCount) => {
    const user = await User.findById(userId);
    const allCollectionAchievements = await Achievement.find({ conditionType: 'COLLECTION_COUNT' });
    
    let newlyUnlocked = [];
    let changed = false;

    allCollectionAchievements.forEach(ach => {
        // Buscamos si el usuario ya tiene este logro guardado
        const hasAchievementIndex = user.unlockedAchievements.findIndex(
            ua => ua.achievement.toString() === ach._id.toString()
        );
        
        // Cumple la condición con su número actual de sets?
        const qualifies = collectionCount >= ach.conditionValue;

        if (qualifies && hasAchievementIndex === -1) {
            // Si cumple y no lo tiene, se lo damos
            user.unlockedAchievements.push({ achievement: ach._id });
            newlyUnlocked.push(ach);
            changed = true;
        } else if (!qualifies && hasAchievementIndex !== -1) {
            // No cumple y lo tiene, se le quita
            user.unlockedAchievements.splice(hasAchievementIndex, 1);
            changed = true;
        }
    });

    // Solo tocamos la base de datos si ha habido algún cambio
    if (changed) {
        await user.save();
    }

    return newlyUnlocked; // Si ha desbloqueado alguno
};

// Devuelve todos los logros e indica si el usuario los tiene
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