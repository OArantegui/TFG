const crypto = require('crypto');

/**
 * Genera la evolución de mercado simulada desde el lanzamiento hasta hoy.
 */
const generateMockMarketData = (setId, numParts, year, rrp, availability, exitDate, launchDate) => {
    //El set siempre se comporta igual cada vez que lo consultas
    const hash = crypto.createHash('md5').update(setId).digest('hex');
    const seed = parseInt(hash.substring(0, 8), 16);

    const now = new Date();
    // Si no hay fecha exacta de lanzamiento, asumimos el 1 de enero del año de salida
    const start = launchDate ? new Date(launchDate) : new Date(year, 0, 1);
    
    start.setDate(1);
    start.setHours(0, 0, 0, 0);
    
    //Definición de precios iniciales
    let basePrice = rrp ? rrp : ((numParts && numParts > 0) ? (numParts * 0.10) : 20.0); //si no hay precio oficial, simulamos
    let currentMovingPrice = basePrice;
    
    //Parámetros que varian precio
    const isExclusive = availability && availability.toLowerCase().includes('exclusive');
    const retailDiscount = isExclusive ? 0 : (seed % 15) / 100; // Descuento en tienda (0-15%)
    const scarcityJump = 1.15 + ((seed % 15) / 100); // Salto al retirar (15-30%)
    const annualGrowth = 1.05 + ((seed % 5) / 100);  // Crecimiento anual post-retiro (5-10%)
    const monthlyGrowthFactor = Math.pow(annualGrowth, 1/12); // Convertimos anual a mensual

    const history = [];
    let tempDate = new Date(start);
    let hasRetiredInSim = false;

    while (tempDate <= now) {
        // Retirado
        if (!hasRetiredInSim && exitDate) {
            if (tempDate > new Date(exitDate)) {
                hasRetiredInSim = true;
                currentMovingPrice = currentMovingPrice * scarcityJump;
            }
        } else if (!hasRetiredInSim && !exitDate) {
            // Si no hay fecha oficial, simulamos retiro a los 24 meses
            const monthsOld = (tempDate.getFullYear() - start.getFullYear()) * 12 + (tempDate.getMonth() - start.getMonth());
            if (monthsOld > 24) {
                hasRetiredInSim = true;
                currentMovingPrice = currentMovingPrice * scarcityJump;
            }
        }

        let priceThisMonth = currentMovingPrice;

        if (!hasRetiredInSim) {
            //solo variamos con el descuento si esta en tiendas
            priceThisMonth = basePrice * (1 - retailDiscount);
        } else {
            // Una vez retirado, el precio base del mercado sube mensualmente
            currentMovingPrice = currentMovingPrice * monthlyGrowthFactor;
            priceThisMonth = currentMovingPrice;
        }

        // Añadimos "ruido" de mercado (-1.5% a +1.5%) para que no sea una línea perfecta
        const noise = (((seed + tempDate.getMonth()) % 30) - 15) / 1000;
        
        history.push({
            month: tempDate.toISOString().substring(0, 7),
            price: parseFloat((priceThisMonth * (1 + noise)).toFixed(2))
        });

        // Avanzamos al mes siguiente
        tempDate.setMonth(tempDate.getMonth() + 1);
    }

    //El valor actual es el último punto de la historia
    const currentMarketValue = history[history.length - 1].price;

    return {
        setId,
        estimatedRetailPrice: parseFloat(basePrice.toFixed(2)),
        currentMarketValue: currentMarketValue,
        isRetired: hasRetiredInSim,
        history: history // Enviamos toda la serie temporal
    };
};

module.exports = { generateMockMarketData };