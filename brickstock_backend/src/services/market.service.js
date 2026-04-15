const crypto = require('crypto');

const generateMockMarketData = (setId, numParts, year, rrp, availability, exitDate) => {
    // Semilla determinista
    const hash = crypto.createHash('md5').update(setId).digest('hex');
    const seed = parseInt(hash.substring(0, 8), 16);

    // Si tenemos el RRP real de Brickset, lo usamos. Si por algún motivo Brickset no lo tiene 
    // (a veces pasa en sets promocionales), usamos regla de 0.10€ por pieza como salvavidas.
    let basePrice = rrp ? rrp : ((numParts && numParts > 0) ? (numParts * 0.10) : 20.0);
    
    // Estado del set
    let isRetired = false;
    const currentDate = new Date(); // Hoy
    const currentYear = currentDate.getFullYear();
    const setYear = year || currentYear;
    const age = Math.max(0, currentYear - setYear);

    if (exitDate) {
        // Si tenemos la fecha oficial de retirada, comprobamos si ya ha pasado
        const exit = new Date(exitDate);
        isRetired = currentDate > exit; 
    } else if (availability) {
        // Por si no esta escrito bien
        const availLower = availability.toLowerCase();
        isRetired = availLower.includes('retired'); 
    } else {
        // Si no tenemos fecha en el objeto, simulamos
        isRetired = age > 3; 
    }

    // Valor de mercado simulado
    let currentMarketValue = basePrice;

    if (!isRetired) {
        // EN TIENDAS (Retail): 
        // Si el set es "Exclusive" (solo se vende en tiendas oficiales LEGO), no suele haber rebajas.
        const isExclusive = availability && availability.toLowerCase().includes('exclusive');
        const discount = isExclusive ? 0 : (seed % 15) / 100; 
        currentMarketValue = basePrice * (1 - discount);
    } else {
        // DESCATALOGADO (Retired): 
        // Pegan un salto por escasez (entre un 15% y un 30%)
        const scarcityJump = 1.15 + ((seed % 15) / 100); 
        
        // Crecimiento anual sostenido (aprox 7% por año tras descatalogarse)
        const yearsRetired = Math.max(1, age - 2); 
        currentMarketValue = basePrice * scarcityJump * Math.pow(1.07, yearsRetired);
    }

    // Añadir un poco de "ruido" de mercado único para cada set (-5% a +5%)
    const variability = ((seed % 10) - 5) / 100; 
    currentMarketValue = currentMarketValue * (1 + variability);

    // Generar la evolución de los últimos 6 meses para la gráfica
    const history = [];
    let pricePoint = currentMarketValue * 0.85; // Hace 6 meses estaba un 15% más barato
    
    for (let i = 5; i >= 0; i--) {
        const d = new Date();
        d.setMonth(d.getMonth() - i);
        
        // Variación mensual (imita la fluctuación del mercado)
        const monthVar = (((seed + i) % 10) - 5) / 100; // -5% a +5%
        pricePoint = pricePoint * (1 + monthVar + 0.02); // +2% tendencia alcista mensual

        history.push({
            month: d.toISOString().substring(0, 7), // Formato "YYYY-MM"
            price: parseFloat(pricePoint.toFixed(2))
        });
    }

    // Asegurarnos de que el último punto de la gráfica cuadre exacto con el valor actual
    history[history.length - 1].price = parseFloat(currentMarketValue.toFixed(2));

    return {
        setId: setId,
        estimatedRetailPrice: parseFloat(basePrice.toFixed(2)),
        currentMarketValue: parseFloat(currentMarketValue.toFixed(2)),
        isRetired: isRetired, // ¡Bug solucionado para el Frontend!
        history: history
    };
};

module.exports = {
    generateMockMarketData
};