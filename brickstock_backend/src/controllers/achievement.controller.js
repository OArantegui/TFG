const achievementService = require('../services/achievement.service');

const getMyAchievements = async (req, res) => {
    try {
        const achievements = await achievementService.getUserAchievements(req.user.id);
        res.json({ success: true, data: achievements });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

module.exports = { getMyAchievements };