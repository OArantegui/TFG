import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/collection_provider.dart';
import '../services/api_service.dart';
import '../models/minifigure.dart';
import '../models/lego_set.dart';
import '../widgets/market_data_widget.dart';
import '../widgets/history_chart_widget.dart'; // IMPORTANTE
import 'set_details_screen.dart';
import 'minifig_details_screen.dart';

enum CollectionMode { sets, minifigs }

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  CollectionMode _selectedMode = CollectionMode.sets;
  String _selectedFilter = 'ALL'; // Estado para el filtro en pantalla ancha

  @override
  void initState() {
    super.initState();
    Future.microtask(() => Provider.of<CollectionProvider>(context, listen: false).loadCollection());
  }

  // Lógica de filtrado de datos para la gráfica
  List<dynamic> _getFilteredHistory(List<dynamic> fullHistory) {
    int itemsToTake = fullHistory.length;
    switch (_selectedFilter) {
      case '6M': itemsToTake = 6; break;
      case '1Y': itemsToTake = 12; break;
      case '5Y': itemsToTake = 60; break;
      case 'ALL': default: itemsToTake = fullHistory.length; break;
    }
    if (itemsToTake > fullHistory.length) itemsToTake = fullHistory.length;
    return fullHistory.sublist(fullHistory.length - itemsToTake);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CollectionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Colección'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.orange), 
            onPressed: () => provider.loadCollection(forceRefresh: true)
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 900) {
                  return _buildWideLayout(provider);
                } else {
                  return _buildNarrowLayout(provider);
                }
              },
            ),
    );
  }

  // --- LAYOUT ESTRECHO (MÓVIL) ---
  Widget _buildNarrowLayout(CollectionProvider provider) {
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildSummaryHeader(provider),
        const SizedBox(height: 16),
        _buildModeToggle(),
        const SizedBox(height: 10),
        Expanded(
          child: _selectedMode == CollectionMode.sets 
              ? _buildSetsList(provider) 
              : _buildMinifigsList(provider),
        ),
      ],
    );
  }

  // --- LAYOUT ANCHO (WEB / TABLET) ---
  Widget _buildWideLayout(CollectionProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // COLUMNA IZQUIERDA: RESUMEN Y GRÁFICA (40%)
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSummaryContent(provider), // El cuadro de valores
                  const SizedBox(height: 30),
                  
                  // CABECERA GRÁFICA CON FILTROS
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10, // Espacio horizontal si se juntan
                    runSpacing: 10, // Espacio vertical si saltan de línea
                    children: [
                      const Text('Evolución Colección', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      _buildFilterChips(),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // GRÁFICA GLOBAL INCRUSTADA
                  if (provider.collectionMarketDataFuture != null)
                    FutureBuilder<Map<String, dynamic>?>(
                      future: provider.collectionMarketDataFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Colors.orange));
                        }
                        if (!snapshot.hasData || snapshot.data == null) return const SizedBox.shrink();

                        final fullHistory = snapshot.data!['history'] as List<dynamic>;
                        final filteredHistory = _getFilteredHistory(fullHistory);

                        return Container(
                          height: 350,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: HistoryChartWidget(history: filteredHistory),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 40),

          // COLUMNA DERECHA: SELECTOR Y LISTA (60%)
          Expanded(
            flex: 6,
            child: Column(
              children: [
                _buildModeToggle(),
                const SizedBox(height: 16),
                Expanded(
                  child: _selectedMode == CollectionMode.sets 
                      ? _buildSetsList(provider) 
                      : _buildMinifigsList(provider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- COMPONENTES REUTILIZABLES ---

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 6.0, // Espacio horizontal entre botones
      runSpacing: 6.0, // Espacio vertical por si se apilan
      children: ['6M', '1Y', '5Y', 'ALL'].map((filter) {
        final isSelected = _selectedFilter == filter;
        return ChoiceChip(
          label: Text(filter, style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.bold
          )),
          selected: isSelected,
          selectedColor: Colors.orange,
          backgroundColor: const Color(0xFF2A2A2A),
          onSelected: (selected) {
            if (selected) setState(() => _selectedFilter = filter);
          },
        );
      }).toList(),
    );
  }

  Widget _buildSummaryContent(CollectionProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSummaryValue('VALOR COLECCIÓN', '${provider.totalCollectionValue.toStringAsFixed(2)} €', Colors.white),
          _buildSummaryValue('MINIFIGURAS', '${provider.totalMinifigures}', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildSummaryValue(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor, fontSize: 26, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // Mantenemos el header original para móvil
  Widget _buildSummaryHeader(CollectionProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryValue('VALOR COLECCIÓN', '${provider.totalCollectionValue.toStringAsFixed(2)} €', Colors.white),
              _buildSummaryValue('MINIFIGURAS', '${provider.totalMinifigures}', Colors.orange),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(color: Colors.white10, height: 1),
          if (provider.collectionMarketDataFuture != null)
            MarketDataWidget(
              setNum: "GLOBAL",
              marketDataFuture: provider.collectionMarketDataFuture!,
              showCards: false, 
              showTitle: false, 
              buttonLabel: 'Ver Evolución de Mercado',
            ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return SegmentedButton<CollectionMode>(
      style: SegmentedButton.styleFrom(
        backgroundColor: const Color(0xFF2D2D2D),
        foregroundColor: Colors.white,
        selectedBackgroundColor: Colors.orange,
        side: const BorderSide(color: Colors.white10),
      ),
      segments: const [
        ButtonSegment(value: CollectionMode.sets, label: Text('Sets'), icon: Icon(Icons.inventory_2)),
        ButtonSegment(value: CollectionMode.minifigs, label: Text('Minifiguras'), icon: Icon(Icons.smart_toy)),
      ],
      selected: {_selectedMode},
      onSelectionChanged: (newSelection) => setState(() => _selectedMode = newSelection.first),
    );
  }

  Widget _buildSetsList(CollectionProvider provider) {
    if (provider.collection.isEmpty) {
      return const Center(child: Text('No tienes sets en tu colección', style: TextStyle(color: Colors.white54)));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: provider.collection.length,
      itemBuilder: (context, index) {
        final item = provider.collection[index];
        return Card(
          color: const Color(0xFF2A2A2A),
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ListTile(
            leading: _buildItemImage(item.imgUrl),
            title: Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('${item.setNum} • ${item.quantity} x ${item.purchasePrice}€', style: const TextStyle(color: Colors.grey)),
            trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _confirmDeleteSet(context, provider, item.id)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SetDetailsScreen(legoSet: LegoSet(setNum: item.setNum, name: item.name, numParts: item.numParts, imgUrl: item.imgUrl, year: item.year, themeId: item.themeId)))),
          ),
        );
      },
    );
  }

  Widget _buildMinifigsList(CollectionProvider provider) {
    if (provider.minifigs.isEmpty) {
      return const Center(child: Text('No tienes minifiguras en tu colección', style: TextStyle(color: Colors.white54)));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: provider.minifigs.length,
      itemBuilder: (context, index) {
        final fig = provider.minifigs[index];
        return Card(
          color: const Color(0xFF2A2A2A),
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ListTile(
            leading: _buildItemImage(fig.imageUrl),
            title: Text(fig.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('ID: ${fig.figNum} • Cantidad: ${fig.quantity}', style: const TextStyle(color: Colors.grey)),
            trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _confirmDeleteMinifig(context, provider, fig)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MinifigDetailsScreen(minifigure: fig))),
          ),
        );
      },
    );
  }

  Widget _buildItemImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6.0),
      child: Container(
        width: 50, height: 50, color: Colors.white,
        child: CachedNetworkImage(imageUrl: ApiService().getProxyUrl(url), fit: BoxFit.contain),
      ),
    );
  }

  // --- DIÁLOGOS DE CONFIRMACIÓN (Omitidos para brevedad, mantener los que ya tenías) ---
  void _confirmDeleteSet(BuildContext context, CollectionProvider provider, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('Eliminar Set', style: TextStyle(color: Colors.white)),
        content: const Text('¿Seguro que quieres eliminar este set de tu colección?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              provider.deleteFromCollection(id);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ); 
  }
  void _confirmDeleteMinifig(BuildContext context, CollectionProvider provider, Minifigure fig) { 
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('Eliminar Minifigura', style: TextStyle(color: Colors.white)),
        content: const Text('¿Seguro que quieres eliminar esta minifigura de tu colección?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              if (fig.id != null) {
                provider.deleteMinifig(fig.id!);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ); 
  }
}