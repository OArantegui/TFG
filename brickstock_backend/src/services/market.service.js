/*const crypto = require('crypto');

const generateMockMarketData = (setId, numParts, year) => {
    // 1. Crear una semilla determinista basada en el ID del set (ej. "42115-1")
    // Esto asegura que si consultas el mismo set mañana, los datos no cambian mágicamente.
    const hash = crypto.createHash('md5').update(setId).digest('hex');
    const seed = parseInt(hash.substring(0, 8), 16);

    // 2. Precio base inicial (aprox. 0.10€ por pieza)
    let basePrice = (numParts && numParts > 0) ? (numParts * 0.10) : 20.0;
    
    // 3. Revalorización por antigüedad (simulamos que sube un 3% por año desde su lanzamiento)
    const currentYear = new Date().getFullYear();
    const setYear = year || currentYear;
    const age = Math.max(0, currentYear - setYear);
    
    // Por norma general, un set dura 2 años en tiendas
    const isRetired = age > 3;

    let currentMarketValue = basePrice * Math.pow(1.03, age);

    if (!isRetired) {
        // EN TIENDAS: El valor de mercado suele ser el retail con algún descuento ocasional
        // Generamos un "descuento" aleatorio pero fijo por set entre 0% y 15%
        const discount = (seed % 15) / 100; 
        currentMarketValue = basePrice * (1 - discount);
    } else {
        // DESCATALOGADO: Pegan un salto por escasez (+15%) y luego suben un ~7% anual
        const yearsRetired = age - 2;
        currentMarketValue = basePrice * 1.15 * Math.pow(1.07, yearsRetired);
    }

    // Añadir un poco de "ruido" de mercado único para cada set (-5% a +5%)
    const variability = ((seed % 10) - 5) / 100; 
    currentMarketValue = currentMarketValue * (1 + variability);

    // 5. Generar la evolución de los últimos 6 meses para tu gráfica
    const history = [];
    let pricePoint = currentMarketValue * 0.85; // Empezamos hace 6 meses un 15% más barato
    
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

    return {
        setId: setId,
        estimatedRetailPrice: parseFloat(basePrice.toFixed(2)),
        currentMarketValue: parseFloat(history[history.length - 1].price),
        history: history
    };
};

module.exports = {
    generateMockMarketData
};*/
const crypto = require('crypto');

// AÑADIDO: Nuevos parámetros 'rrp' (Precio Oficial) y 'availability' (Estado)
const generateMockMarketData = (setId, numParts, year, rrp, availability, exitDate) => {
    // 1. Semilla determinista (se mantiene igual, es una genialidad para tu TFG)
    const hash = crypto.createHash('md5').update(setId).digest('hex');
    const seed = parseInt(hash.substring(0, 8), 16);

    // 2. PRECIO BASE: 
    // Si tenemos el RRP real de Brickset, lo usamos. Si por algún motivo Brickset no lo tiene 
    // (a veces pasa en sets promocionales), usamos tu regla de 0.10€ por pieza como salvavidas.
    let basePrice = rrp ? rrp : ((numParts && numParts > 0) ? (numParts * 0.10) : 20.0);
    
    // 3. ESTADO DEL SET (Descatalogado o En tiendas):
    let isRetired = false;
    const currentDate = new Date(); // Fecha de hoy
    const currentYear = currentDate.getFullYear();
    const setYear = year || currentYear;
    const age = Math.max(0, currentYear - setYear);

    if (exitDate) {
        // Si tenemos la fecha oficial de retirada, comprobamos si ya ha pasado
        const exit = new Date(exitDate);
        isRetired = currentDate > exit; 
    } else if (availability) {
        // Fallback 1: Por si algún set raro no tiene fecha pero dice "Retired"
        const availLower = availability.toLowerCase();
        isRetired = availLower.includes('retired'); 
    } else {
        // Fallback 2: Nuestra regla de seguridad antigua
        isRetired = age > 3; 
    }

    // 4. CÁLCULO DEL VALOR DE MERCADO REVISADO
    let currentMarketValue = basePrice;

    if (!isRetired) {
        // EN TIENDAS (Retail): 
        // Si el set es "Exclusive" (solo se vende en tiendas oficiales LEGO), no suele haber rebajas.
        // Si es normal, simulamos un descuento en Amazon/Juguettos del 0% al 15%
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

    // 5. Generar la evolución de los últimos 6 meses para la gráfica
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