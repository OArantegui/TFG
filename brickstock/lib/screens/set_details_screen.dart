import 'dart:io'; // Para detectar plataforma
import 'dart:math'; // <--- NECESARIO PARA RANDOM
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
  final List<String> _extraImages = [
    // Como fallback usaremos imágenes de ejemplo si no hay más
    'https://images.brickset.com/sets/additional/75192-1/75192_alt1.jpg',
    'https://images.brickset.com/sets/additional/75192-1/75192_alt2.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // 1. GESTIÓN DE IMÁGENES
    // Aseguramos que la imagen principal sea la primera
    if (!_extraImages.contains(widget.legoSet.imgUrl)) {
      _extraImages.insert(0, widget.legoSet.imgUrl);
    }

    // 2. GENERACIÓN DE PRECIOS SIMULADOS
    _generateSimulatedPrices();
  }

  void _generateSimulatedPrices() {
    // REGLA DE ORO: Precio estimado ~ 0.10€ por pieza
    // Si el set tiene 0 piezas (error de API), asumimos 100 piezas por defecto
    int parts = widget.legoSet.numParts > 0 ? widget.legoSet.numParts : 100;
    double basePrice = parts * 0.10;

    // Lista de tiendas disponibles
    final List<String> stores = [
      'Lego Store',
      'Amazon',
      'eBay (Nuevo)',
      'BrickLink',
      'El Corte Inglés',
      'Toys "R" Us',
    ];

    final random = Random();

    // Generamos precios para 4 tiendas aleatorias de la lista
    // Barajamos la lista de tiendas para que no siempre salgan las mismas
    stores.shuffle();
    final selectedStores = stores.take(4).toList();

    _mockPrices = selectedStores.map((storeName) {
      // Factor de variación: entre 0.85 (-15%) y 1.15 (+15%)
      double variation = 0.85 + random.nextDouble() * 0.30;

      // Casos especiales para darle realismo:
      // - eBay suele ser más caro por especulación (+20% extra a veces)
      if (storeName.contains('eBay')) variation += 0.2;
      // - Amazon suele ajustar más el precio
      if (storeName.contains('Amazon')) variation -= 0.05;

      double finalPrice = basePrice * variation;

      return {
        'store': storeName,
        'price': double.parse(
          finalPrice.toStringAsFixed(2),
        ), // Redondear a 2 decimales
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
    final bool showArrows =
        kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    // Calcular mínimo para destacar
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
            // --- CARRUSEL ---
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
                      return Image.network(
                        _extraImages[index],
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, _, __) =>
                            const Icon(Icons.broken_image, size: 100),
                      );
                    },
                  ),
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
                  // Dots indicator
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

            // --- INFO DEL SET ---
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

                  // --- COMPARADOR ---
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

                  // Lista de precios generada
                  ..._mockPrices.map((priceData) {
                    final bool isCheapest = priceData['price'] == minPrice;
                    return Card(
                      elevation: isCheapest ? 4 : 1,
                      color: isCheapest
                          ? const Color.fromARGB(255, 35, 37, 35)
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
                            color: isCheapest
                                ? Colors.green.shade800
                                : Colors.black,
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

                  // --- BOTÓN NOTIFICAR ---
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
