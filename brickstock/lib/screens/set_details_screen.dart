import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; 
import 'package:url_launcher/url_launcher.dart';
import '../models/lego_set.dart';
import '../services/api_service.dart';
import '../widgets/minifigures_bottom_sheet.dart';
import '../widgets/market_data_widget.dart';
import '../widgets/instructions_dialog.dart';
import '../widgets/history_chart_widget.dart'; // NUEVO WIDGET IMPORTADO

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

  String _selectedFilter = 'ALL';

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

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 24, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text(
                value, 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                softWrap: true, 
                maxLines: 2,    
                overflow: TextOverflow.ellipsis, 
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- LÓGICA DE AÑADIR A DESEADOS (Extraída para reutilizarla en ambos layouts) ---
  Widget _buildWishlistButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.favorite_border, color: Colors.pinkAccent),
        label: const Text('Añadir a deseados'),
        onPressed: () async {
          final double priceToSave = _estimatedRetailPrice; 
          final result = await ApiService().addToWishlist(widget.legoSet.setNum, priceToSave);

          if (result['warning'] == true) {
            if (!mounted) return;
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('⚠️ Límite Excedido'),
                content: Text(result['message']),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await ApiService().addToWishlist(widget.legoSet.setNum, priceToSave, force: true);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Añadido ignorando el límite'), backgroundColor: Colors.orange),
                        );
                      }
                    },
                    child: const Text('Ignorar y Añadir', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          } else if (result['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Añadido a deseados!'), backgroundColor: Colors.green));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Error'), backgroundColor: Colors.red));
          }
        },
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
      ),
    );
  }

  // --- LAYOUT PARA MÓVILES (Tu diseño original) ---
  Widget _buildNarrowLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 300,
            width: double.infinity,
            child: CachedNetworkImage(
              imageUrl: _getImageUrl(widget.legoSet.imgUrl), 
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.orange)),
              errorWidget: (context, url, error) => Container(
                color: const Color(0xFF2A2A2A),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, 
                  children: const [
                    Icon(Icons.image_not_supported, size: 50, color: Colors.grey), 
                    SizedBox(height: 8), 
                    Text("Imagen no disponible", style: 
                    TextStyle(color: Colors.grey))]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.legoSet.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                MarketDataWidget(setNum: widget.legoSet.setNum, marketDataFuture: _marketDataFuture!),
                const SizedBox(height: 25),
                const Divider(),
                const SizedBox(height: 15),
                _buildDetailsAndManual(context),
                const SizedBox(height: 30),
                _buildWishlistButton(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // LAYOUT PARA PANTALLAS ANCHAS
  Widget _buildWideLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // COLUMNA IZQUIERDA (Imagen y Precios)
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 350,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2A2A) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: CachedNetworkImage(
                    imageUrl: _getImageUrl(widget.legoSet.imgUrl), 
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.orange)),
                    errorWidget: (context, url, error) => const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.image_not_supported, size: 50, color: Colors.grey), SizedBox(height: 8), Text("Imagen no disponible", style: TextStyle(color: Colors.grey))]),
                  ),
                ),
                const SizedBox(height: 20),
                MarketDataWidget(
                  setNum: widget.legoSet.setNum, 
                  marketDataFuture: _marketDataFuture!,
                  showButton: false, // Ocultamos el botón porque la gráfica ya está fuera
                ),
                const SizedBox(height: 30),
                _buildWishlistButton(),
                const SizedBox(height: 80),
              ],
            ),
          ),
          
          const SizedBox(width: 40),

          // COLUMNA DERECHA (Detalles y Gráfica con Filtros)
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.legoSet.name, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 25),
                
                _buildDetailsAndManual(context),
                
                const SizedBox(height: 40),
                
                // CABECERA DE LA GRÁFICA CON FILTROS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Evolución del Mercado', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    
                    // BOTONES DE FILTRO INTEGRADOS
                    Row(
                      children: ['6M', '1Y', '5Y', 'ALL'].map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: ChoiceChip(
                            label: Text(filter, style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold
                            )),
                            selected: isSelected,
                            selectedColor: Colors.orange,
                            onSelected: (bool selected) {
                              if (selected) {
                                setState(() => _selectedFilter = filter);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                FutureBuilder<Map<String, dynamic>?>(
                  future: _marketDataFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.orange));
                    }
                    if (!snapshot.hasData || snapshot.data == null) return const SizedBox.shrink();

                    final fullHistory = snapshot.data!['history'] as List<dynamic>;
                    // FILTRAMOS LOS DATOS ANTES DE PASARLOS AL WIDGET
                    final filteredHistory = _getFilteredHistory(fullHistory);

                    return Container(
                      height: 350,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: HistoryChartWidget(history: filteredHistory),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Método para recortar el historial según el filtro seleccionado
  List<dynamic> _getFilteredHistory(List<dynamic> fullHistory) {
    int itemsToTake = fullHistory.length;

    switch (_selectedFilter) {
      case '6M': itemsToTake = 6; break;
      case '1Y': itemsToTake = 12; break;
      case '5Y': itemsToTake = 60; break;
      case 'ALL': default: itemsToTake = fullHistory.length; break;
    }

    if (itemsToTake > fullHistory.length) {
      itemsToTake = fullHistory.length;
    }

    return fullHistory.sublist(fullHistory.length - itemsToTake);
  }

  // --- WIDGET REUTILIZABLE: Cuadrícula de detalles y manual ---
  Widget _buildDetailsAndManual(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Detalles del Set', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            InkWell(
              onTap: () async {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Buscando manuales...'), duration: Duration(seconds: 1)));
                final urls = await ApiService().getSetInstructions(widget.legoSet.setNum);
                if (!context.mounted) return;

                if (urls.isNotEmpty) {
                  if (urls.length == 1) {
                    final uri = Uri.parse(urls.first);
                    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    showDialog(context: context, builder: (context) => InstructionsDialog(urls: urls));
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay manuales en PDF disponibles.'), backgroundColor: Colors.orange));
                }
              },
              child: Row(
                children: const [
                  Icon(Icons.help_outline, size: 18, color: Colors.orange),
                  SizedBox(width: 4),
                  Text('Manual', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem(Icons.tag, 'Número', widget.legoSet.setNum),
                    const SizedBox(height: 15),
                    FutureBuilder<String>(
                      future: ApiService().getThemeName(widget.legoSet.themeId),
                      builder: (context, snapshot) {
                        final themeName = snapshot.hasData ? snapshot.data! : 'Cargando...';
                        return _buildDetailItem(Icons.category, 'Tema', themeName);
                      },
                    ),
                  ],
                ),
              ),
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      
      // EL ORQUESTADOR DEL DISEÑO RESPONSIVO
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Si la pantalla es más ancha de 800px (Tablets / Web), usamos dos columnas
          if (constraints.maxWidth >= 800) {
            return _buildWideLayout(context);
          } else {
            // Si es un móvil, usamos tu diseño original en cascada
            return _buildNarrowLayout(context);
          }
        },
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
              tooltip: 'Ver Minifiguras',
              child: const Icon(Icons.smart_toy), 
            ),

            FloatingActionButton.extended(
              heroTag: 'btn_collection_${widget.legoSet.setNum}', 
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guardando')));
                final result = await ApiService().addToCollection(widget.legoSet.setNum, _currentMarketValue);
                ScaffoldMessenger.of(context).hideCurrentSnackBar();

                if (result['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('¡${widget.legoSet.name} añadido a tu colección!'), backgroundColor: Colors.green));
                  if (result['newAchievements'] != null && result['newAchievements'].isNotEmpty) {
                    final List newAchievements = result['newAchievements'];

                    // Recorremos todos los logros que hayan saltado
                    for (var achievementData in newAchievements) {
                      // Comprobamos que el widget siga en pantalla antes de lanzar el popup
                      if (!mounted) return; 

                      // El 'await' es la clave: detiene el bucle hasta que se cierre este Dialog
                      await showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Row(children: [
                            Icon(Icons.stars, color: Colors.amber, size: 30), 
                            SizedBox(width: 10), 
                            Text('¡Nuevo Logro!')
                          ]),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                achievementData['name'], 
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), 
                                textAlign: TextAlign.center
                              ),
                              const SizedBox(height: 10),
                              Text(achievementData['description'], textAlign: TextAlign.center),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx), // Cierra el modal y permite que el bucle continúe
                              child: const Text('¡Genial!', style: TextStyle(color: Colors.orange))
                            )
                          ],
                        ),
                      );
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Error al guardar.'), backgroundColor: Colors.red));
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