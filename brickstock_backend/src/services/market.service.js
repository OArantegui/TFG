/*const crypto = require('crypto');

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
};*/

const crypto = require('crypto');

/**
 * Genera la evolución de mercado simulada desde el lanzamiento hasta hoy.
 */
const generateMockMarketData = (setId, numParts, year, rrp, availability, exitDate, launchDate) => {
    // 1. Semilla determinista: El set siempre se comporta igual cada vez que lo consultas
    const hash = crypto.createHash('md5').update(setId).digest('hex');
    const seed = parseInt(hash.substring(0, 8), 16);

    const now = new Date();
    // Si no hay fecha exacta de lanzamiento, asumimos el 1 de enero del año de salida
    const start = launchDate ? new Date(launchDate) : new Date(year, 0, 1);
    
    // 2. Definición de precios iniciales
    let basePrice = rrp ? rrp : ((numParts && numParts > 0) ? (numParts * 0.10) : 20.0);
    let currentMovingPrice = basePrice;
    
    // 3. Parámetros de "personalidad" del set (basados en la semilla)
    const isExclusive = availability && availability.toLowerCase().includes('exclusive');
    const retailDiscount = isExclusive ? 0 : (seed % 15) / 100; // Descuento en tienda (0-15%)
    const scarcityJump = 1.15 + ((seed % 15) / 100); // Salto al retirar (15-30%)
    const annualGrowth = 1.05 + ((seed % 5) / 100);  // Crecimiento anual post-retiro (5-10%)
    const monthlyGrowthFactor = Math.pow(annualGrowth, 1/12); // Convertimos anual a mensual

    const history = [];
    let tempDate = new Date(start);
    let hasRetiredInSim = false;

    // 4. Bucle de simulación: Caminamos desde el pasado hasta el presente
    while (tempDate <= now) {
        // ¿Ha llegado el momento de la retirada?
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
            // Mientras está en tiendas, el precio fluctúa según el descuento retail
            priceThisMonth = basePrice * (1 - retailDiscount);
        } else {
            // Una vez retirado, el precio base del mercado sube mensualmente
            currentMovingPrice = currentMovingPrice * monthlyGrowthFactor;
            priceThisMonth = currentMovingPrice;
        }

        // Añadimos "ruido" de mercado (-1.5% a +1.5%) para que no sea una línea perfecta
        const noise = (((seed + tempDate.getMonth()) % 30) - 15) / 1000;
        
        history.push({
            month: tempDate.toISOString().substring(0, 7), // Formato YYYY-MM
            price: parseFloat((priceThisMonth * (1 + noise)).toFixed(2))
        });

        // Avanzamos al mes siguiente
        tempDate.setMonth(tempDate.getMonth() + 1);
    }

    // 5. El valor actual es el último punto de la historia
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