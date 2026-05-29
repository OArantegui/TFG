const mongoose = require('mongoose');

const bricksetCacheSchema = new mongoose.Schema({
    setID: { type: Number, required: true, unique: true }, // ID de Brickset
    number: { type: String, required: true, index: true }, // ID de rebrickable
    name: { type: String },
    year: { type: Number },
    theme: { type: String },
    themeGroup: { type: String },
    subtheme: { type: String },
    category: { type: String },
    availability: { type: String },
    released: { type: Boolean },
    pieces: { type: Number },
    minifigs: { type: Number },
    launchDate: { type: Date },
    exitDate: { type: Date },
    
    image: {
        thumbnailURL: { type: String },
        imageURL: { type: String }
    },
    
    LEGOCom: { type: Map, of: new mongoose.Schema({
        retailPrice: { type: Number },
        dateFirstAvailable: { type: Date }
    }, { _id: false })},
    
    rating: { type: Number },
    
    ageRange: {
        min: { type: Number }
    },
    
    dimensions: {
        height: { type: Number },
        width: { type: Number },
        depth: { type: Number }
    },
    
    modelDimensions: {
        dimension1: { type: Number },
        dimension2: { type: Number },
        dimension3: { type: Number }
    },
    
    barcode: {
        EAN: { type: String, index: true }, // Índice para escáner en Europa
        UPC: { type: String, index: true }  // Índice para escáner en América
    },
    
    itemNumber: {
        NA: { type: String },
        EU: { type: String }
    },

    // Campo de control para saber cuándo caduca la info
    lastUpdatedServer: { type: Date, default: Date.now }
});

module.exports = mongoose.model('BricksetCache', bricksetCacheSchema);