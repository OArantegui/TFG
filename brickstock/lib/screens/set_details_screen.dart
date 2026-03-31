import 'dart:io'; // Para detectar plataforma
import 'dart:math'; // Para Random
import 'package:cached_network_image/cached_network_image.dart'; // <--- NUEVO: Para caché y mejor rendimiento
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:flutter/material.dart';
import '../models/lego_set.dart';
import '../services/api_service.dart';
import '../widgets/minifigures_bottom_sheet.dart';

class SetDetailsScreen extends StatefulWidget {
  final LegoSet legoSet;

  const SetDetailsScreen({super.key, required this.legoSet});

  @override
  State<SetDetailsScreen> createState() => _SetDetailsScreenState();
}

class _SetDetailsScreenState extends State<SetDetailsScreen> {
  late PageController _pageController;

  // Lista dinámica de precios que generaremos
  List<Map<String, dynamic>> _mockPrices = [];

  // Lista de imágenes
  final List<String> _extraImages = [];

  @override
  void initState() {
    super.initState();

    //Generacion imagen
    _extraImages.add(widget.legoSet.imgUrl);

    //Generacion precios
    _generateSimulatedPrices();
  }

  // Función refactorizada aplicando DRY
  String _getImageUrl(String originalUrl) {
    if (kIsWeb) {
      return ApiService().getProxyUrl(originalUrl);
    }
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

    // Generamos un número entero único basado en el código del set (ej. "42115-1")
    final int seed = widget.legoSet.setNum.hashCode;
    final random = Random(seed); // Le pasamos la semilla al generador

    // Usamos nuestro random "trucado" para mezclar las tiendas
    stores.shuffle(random);
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

  void _showMinifiguresBottomSheet(BuildContext context, String setNum) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        // TFG: Inyectamos nuestro nuevo Widget encapsulado
        return MinifiguresBottomSheet(setNum: setNum);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
            // --- IMAGEN PRINCIPAL DEL SET ---
            SizedBox(
              height: 300,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: _getImageUrl(
                  widget.legoSet.imgUrl,
                ), // Usamos tu función con proxy
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.orange),
                ),
                errorWidget: (context, url, error) => Container(
                  color: const Color(0xFF2A2A2A),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Imagen no disponible",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
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
                      icon: const Icon(
                        Icons.favorite_border,
                        color: Colors.pinkAccent,
                      ),
                      label: const Text('Añadir a deseados'),
                      onPressed: () async {
                        // Intentamos añadir (modo normal, force: false)
                        final priceToSave = minPrice == double.infinity
                            ? 0.0
                            : minPrice;
                        final result = await ApiService().addToWishlist(
                          widget.legoSet.setNum,
                          priceToSave,
                        );

                        if (result['warning'] == true) {
                          // SUPERAMOS EL PRESUPUESTO: Mostramos Alerta
                          if (!mounted) return;
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('⚠️ Límite Excedido'),
                              content: Text(result['message']),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    // Forzamos la inserción (force: true)
                                    await ApiService().addToWishlist(
                                      widget.legoSet.setNum,
                                      priceToSave,
                                      force: true,
                                    );
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Añadido ignorando el límite',
                                          ),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text(
                                    'Ignorar y Añadir',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else if (result['success'] == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('¡Añadido a deseados!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message'] ?? 'Error'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // --- NUEVO BOTÓN MINIFIGURAS (IZQUIERDA) ---
            FloatingActionButton(
              heroTag: 'btn_minifigs', // TFG: Explicación abajo
              onPressed: () => _showMinifiguresBottomSheet(context, widget.legoSet.setNum),
              child: const Icon(Icons.smart_toy), // Icono puro de Material
              tooltip: 'Ver Minifiguras',
            ),

            // --- TU BOTÓN ACTUAL DE COLECCIÓN (DERECHA) ---
            FloatingActionButton.extended(
              heroTag: 'btn_collection', // TFG: Explicación abajo
              onPressed: () async {
                // (Mantiene todo tu código original sin tocar)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Guardando en MongoDB... ⏳')),
                );

                double priceToSave = minPrice == double.infinity ? 0.0 : minPrice;

                bool success = await ApiService().addToCollection(
                  widget.legoSet.setNum,
                  priceToSave,
                );

                ScaffoldMessenger.of(context).hideCurrentSnackBar();

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('¡${widget.legoSet.name} añadido a tu colección! 🚀'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error al guardar. ¿Has iniciado sesión?'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Añadir a Colección'),
            ),
          ],
        ),
      ),
    );
  }
}