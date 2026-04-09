import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; 
import '../models/lego_set.dart';
import '../services/api_service.dart';
import '../widgets/minifigures_bottom_sheet.dart';
import '../widgets/market_data_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class SetDetailsScreen extends StatefulWidget {
  final LegoSet legoSet;

  const SetDetailsScreen({super.key, required this.legoSet});

  @override
  State<SetDetailsScreen> createState() => _SetDetailsScreenState();
}

class _SetDetailsScreenState extends State<SetDetailsScreen> {
  final List<String> _extraImages = [];
  
  Future<Map<String, dynamic>?>? _marketDataFuture;
  double _currentMarketValue = 0.0;
  double _estimatedRetailPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _extraImages.add(widget.legoSet.imgUrl);
    
    _marketDataFuture = ApiService().getSetMarketData(widget.legoSet.setNum);
    
    _marketDataFuture?.then((data) {
      if (mounted && data != null) {
        setState(() {
          _currentMarketValue = (data['currentMarketValue'] as num).toDouble();
          _estimatedRetailPrice = (data['estimatedRetailPrice'] as num).toDouble();
        });
      }
    });
  }

  String _getImageUrl(String originalUrl) {
    if (kIsWeb) {
      return ApiService().getProxyUrl(originalUrl);
    }
    return originalUrl;
  }

  void _showMinifiguresBottomSheet(BuildContext context, String setNum) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return MinifiguresBottomSheet(setNum: setNum);
      },
    );
  }

  // TFG: Helper visual para la nueva cuadrícula de detalles
  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 24, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        // Envolvemos la columna en Expanded para que el texto haga salto de línea si es muy largo
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text(
                value, 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                softWrap: true, // Permite salto de línea
                maxLines: 2,    // Máximo 2 líneas para mantener el diseño limpio
                overflow: TextOverflow.ellipsis, // Si ocupa más de 2 líneas, pone "..."
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- IMAGEN PRINCIPAL DEL SET ---
            SizedBox(
              height: 300,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: _getImageUrl(widget.legoSet.imgUrl), 
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
                  // TÍTULO DEL SET
                  Text(
                    widget.legoSet.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // PRECIOS Y GRÁFICA
                  MarketDataWidget(
                    setNum: widget.legoSet.setNum,
                    marketDataFuture: _marketDataFuture!,
                  ),

                  const SizedBox(height: 25),
                  const Divider(),
                  const SizedBox(height: 15),

                  // Row para 'Detalles' en un lado e instrucciones en otro
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Detalles del Set',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      InkWell(
                        onTap: () async {
                          // Mostramos un pequeño indicador visual si tarda
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Buscando manual... 🔍'), duration: Duration(seconds: 1)),
                          );
                          
                          final url = await ApiService().getSetInstructions(widget.legoSet.setNum);
                          
                          if (url != null && url.isNotEmpty) {
                            final uri = Uri.parse(url);
                            // Abre el navegador/visor PDF nativo
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No hay manual en PDF disponible para este set.'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          }
                        },
                        child: Row(
                          children: [
                            Icon(Icons.help_outline, size: 18, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              'Manual',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.grey.shade900 
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // Columna Izquierda
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailItem(Icons.tag, 'Número', widget.legoSet.setNum),
                              const SizedBox(height: 15),
                              FutureBuilder<String>(
                                future: ApiService().getThemeName(widget.legoSet.themeId),
                                builder: (context, snapshot) {
                                  // Si aún está cargando, mostramos un texto temporal o el ID
                                  final themeName = snapshot.hasData ? snapshot.data! : 'Cargando...';
                                  return _buildDetailItem(Icons.category, 'Tema', themeName);
                                },
                              ),
                            ],
                          ),
                        ),
                        // Columna Derecha
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailItem(Icons.calendar_today, 'Año', widget.legoSet.year.toString()),
                              const SizedBox(height: 15),
                              _buildDetailItem(Icons.extension, 'Piezas', widget.legoSet.numParts.toString()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- BOTÓN AÑADIR A DESEADOS ---
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        Icons.favorite_border,
                        color: Colors.pinkAccent,
                      ),
                      label: const Text('Añadir a deseados'),
                      onPressed: () async {
                        final double priceToSave = _estimatedRetailPrice; 
                        
                        final result = await ApiService().addToWishlist(
                          widget.legoSet.setNum,
                          priceToSave,
                        );

                        if (result['warning'] == true) {
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
                                    await ApiService().addToWishlist(
                                      widget.legoSet.setNum,
                                      priceToSave,
                                      force: true,
                                    );
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Añadido ignorando el límite'),
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
            FloatingActionButton(
              heroTag: 'btn_minifigs_${widget.legoSet.setNum}', 
              onPressed: () => _showMinifiguresBottomSheet(context, widget.legoSet.setNum),
              child: const Icon(Icons.smart_toy), 
              tooltip: 'Ver Minifiguras',
            ),

            FloatingActionButton.extended(
              heroTag: 'btn_collection_${widget.legoSet.setNum}', 
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Guardando en MongoDB... ⏳')),
                );

                final double priceToSave = _currentMarketValue;

                final result = await ApiService().addToCollection(
                  widget.legoSet.setNum,
                  priceToSave,
                );

                ScaffoldMessenger.of(context).hideCurrentSnackBar();

                if (result['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('¡${widget.legoSet.name} añadido a tu colección! 🚀'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  if (result['newAchievements'] != null && result['newAchievements'].isNotEmpty) {
                    final achievementData = result['newAchievements'][0]; 
                    
                    if (!mounted) return;
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Row(
                          children: [
                            Icon(Icons.stars, color: Colors.amber, size: 30),
                            SizedBox(width: 10),
                            Text('¡Nuevo Logro!'),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              achievementData['name'],
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              achievementData['description'],
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('¡Genial!', style: TextStyle(color: Colors.orange)),
                          )
                        ],
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Error al guardar.'),
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