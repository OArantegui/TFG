import 'dart:io'; // Para detectar plataforma
import 'dart:math'; // Para Random
import 'package:cached_network_image/cached_network_image.dart'; // <--- NUEVO: Para caché y mejor rendimiento
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:flutter/material.dart';
import '../models/lego_set.dart';

class SetDetailsScreen extends StatefulWidget {
  final LegoSet legoSet;

  const SetDetailsScreen({super.key, required this.legoSet});

  @override
  State<SetDetailsScreen> createState() => _SetDetailsScreenState();
}

class _SetDetailsScreenState extends State<SetDetailsScreen> {
  late PageController _pageController;
  int _currentImageIndex = 0;

  // Lista dinámica de precios que generaremos
  List<Map<String, dynamic>> _mockPrices = [];

  // Lista de imágenes
  final List<String> _extraImages = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // --- GENERACIÓN DINÁMICA DE IMÁGENES ---
    // 1. Añadimos SIEMPRE la imagen principal de Rebrickable (esa nunca falla)
    _extraImages.add(widget.legoSet.imgUrl);

    // 2. "Adivinamos" 3 imágenes extra usando el patrón de Brickset
    // Ejemplo: Si el set es "75192-1", buscamos "75192_alt1.jpg"
    final setNumBase = widget.legoSet.setNum.split('-')[0]; // Quitamos el "-1"

    // Generamos URLs para alt1, alt2 y alt3
    for (var i = 1; i <= 3; i++) {
      String altUrl =
          'https://images.brickset.com/sets/additional/${widget.legoSet.setNum}/${setNumBase}_alt$i.jpg';
      _extraImages.add(altUrl);
    }

    // 2. GENERACIÓN DE PRECIOS SIMULADOS
    _generateSimulatedPrices();
  }

  // --- FUNCIÓN MÁGICA PARA IMÁGENES (Proxy para Web) ---
  String _getImageUrl(String originalUrl) {
    if (kIsWeb) {
      // Si estamos en Web, usamos el Proxy del Backend para saltar el bloqueo CORS
      final encodedUrl = Uri.encodeComponent(originalUrl);
      return 'http://localhost:3000/api/lego/image-proxy?url=$encodedUrl';
    }
    // Si estamos en Móvil, pedimos la imagen directa (más rápido)
    return originalUrl;
  }

  void _generateSimulatedPrices() {
    // REGLA DE ORO: Precio estimado ~ 0.10€ por pieza
    int parts = widget.legoSet.numParts > 0 ? widget.legoSet.numParts : 100;
    double basePrice = parts * 0.10;

    final List<String> stores = [
      'Lego Store',
      'Amazon',
      'eBay (Nuevo)',
      'BrickLink',
      'El Corte Inglés',
      'Toys "R" Us',
    ];

    final random = Random();
    stores.shuffle();
    final selectedStores = stores.take(4).toList();

    _mockPrices = selectedStores.map((storeName) {
      double variation = 0.85 + random.nextDouble() * 0.30; // +/- 15%

      if (storeName.contains('eBay')) variation += 0.2;
      if (storeName.contains('Amazon')) variation -= 0.05;

      double finalPrice = basePrice * variation;

      return {
        'store': storeName,
        'price': double.parse(finalPrice.toStringAsFixed(2)),
        'url':
            'https://www.google.com/search?q=lego+${widget.legoSet.setNum}+${storeName.replaceAll(' ', '+')}',
      };
    }).toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextImage() {
    if (_currentImageIndex < _extraImages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevImage() {
    if (_currentImageIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showHistoryChart(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Histórico de Precios'),
        content: SizedBox(
          height: 200,
          width: 300,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.show_chart, size: 50, color: Colors.blue),
                SizedBox(height: 10),
                Text('Datos históricos simulados'),
                Text(
                  '(Basado en API v3 Rebrickable)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Detectamos si necesitamos flechas (Web/Escritorio)
    final bool showArrows =
        kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    double minPrice = double.infinity;
    if (_mockPrices.isNotEmpty) {
      minPrice = _mockPrices.map((e) => e['price'] as double).reduce(min);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('BrickStock')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- CARRUSEL DE IMÁGENES MEJORADO ---
            SizedBox(
              height: 300,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: _extraImages.length,
                    onPageChanged: (index) =>
                        setState(() => _currentImageIndex = index),
                    itemBuilder: (ctx, index) {
                      return CachedNetworkImage(
                        imageUrl: _getImageUrl(
                          _extraImages[index],
                        ), // <--- ¡Vital usar el Proxy aquí!
                        fit: BoxFit.contain,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        // Si la imagen "adivinada" no existe (404), mostramos un aviso elegante
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.image_not_supported,
                                size: 40,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                index == 0
                                    ? "Imagen no disponible"
                                    : "Vista extra no disponible",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Flechas de navegación (Solo Web/Desktop)
                  if (showArrows && _currentImageIndex > 0)
                    Positioned(
                      left: 10,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 30),
                        onPressed: _prevImage,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white54,
                        ),
                      ),
                    ),
                  if (showArrows &&
                      _currentImageIndex < _extraImages.length - 1)
                    Positioned(
                      right: 10,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 30),
                        onPressed: _nextImage,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white54,
                        ),
                      ),
                    ),

                  // Indicador de puntos (Dots)
                  Positioned(
                    bottom: 10,
                    child: Row(
                      children: List.generate(_extraImages.length, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentImageIndex == index
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),

            // --- INFO Y PRECIOS ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.legoSet.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Set ${widget.legoSet.setNum} | ${widget.legoSet.year} | ${widget.legoSet.numParts} piezas',
                    style: TextStyle(color: Colors.grey[700], fontSize: 16),
                  ),

                  const SizedBox(height: 20),
                  const Divider(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Comparativa de Precios',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.show_chart),
                        label: const Text('Ver Histórico'),
                        onPressed: () => _showHistoryChart(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Tabla de precios
                  ..._mockPrices.map((priceData) {
                    final bool isCheapest = priceData['price'] == minPrice;
                    return Card(
                      elevation: isCheapest ? 4 : 1,
                      // Pequeño ajuste visual para modo oscuro/claro
                      color: isCheapest
                          ? (Theme.of(context).brightness == Brightness.dark
                                ? Colors.green.shade900.withOpacity(0.3)
                                : Colors.green.shade50)
                          : null,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Icon(
                          Icons.shopping_bag,
                          color: isCheapest ? Colors.green : Colors.grey,
                        ),
                        title: Text(
                          priceData['store'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Text(
                          '${priceData['price']} €',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: isCheapest
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isCheapest ? Colors.green : null,
                          ),
                        ),
                        subtitle: isCheapest
                            ? const Text(
                                '¡Mejor precio estimado!',
                                style: TextStyle(color: Colors.green),
                              )
                            : null,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Abriendo ${priceData['store']}...',
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: const Text('Notificar bajada de precio'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Alerta creada correctamente'),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.legoSet.name} añadido a tu colección'),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Añadir a Colección'),
      ),
    );
  }
}
