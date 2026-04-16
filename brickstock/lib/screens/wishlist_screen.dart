import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/lego_set.dart';
import '../widgets/wishlist_summary_card.dart';
import '../widgets/wishlist_theme_chart.dart'; 
import 'set_details_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _wishlistItems = [];
  double _totalValue = 0.0;
  double _budget = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getWishlistData();
      if (mounted) {
        setState(() {
          _wishlistItems = data['data'] ?? [];
          _budget = (data['budget'] as num).toDouble();
          
          // Calculamos el valor total sumando el targetPrice de cada set
          _totalValue = _wishlistItems.fold(
            0.0, 
            (sum, item) => sum + (item['targetPrice'] as num).toDouble()
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error cargando deseados: $e");
    }
  }

  Map<String, double> _getThemeDistribution() {
    Map<String, double> distribution = {};
    for (var item in _wishlistItems) {
      // Ajusta 'themeName' al nombre del campo que devuelva tu backend Node.js
      String theme = item['themeName'] ?? 'Tema ${item['themeId'] ?? '?'}'; 
      double price = (item['targetPrice'] as num).toDouble();
      
      distribution[theme] = (distribution[theme] ?? 0) + price;
    }
    return distribution;
  }

  String _getImageUrl(String url) {
    return kIsWeb ? _apiService.getProxyUrl(url) : url;
  }

  // ===========================================================================
  // LAYOUTS RESPONSIVOS
  // ===========================================================================

  /*Widget _buildNarrowLayout() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(24),
          ),
          child: WishlistSummaryCard(
            totalValue: _totalValue,
            budget: _budget,
            onBudgetUpdated: _loadWishlist,
          ),
        ),
        const SizedBox(height: 12),
        //const Divider(color: Colors.white10, height: 1),
        // --- NUEVO BOTÓN DE ESTADÍSTICAS ---
        if (_wishlistItems.isNotEmpty)  

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.pie_chart, color: Colors.orange),
              label: const Text('Ver estadísticas de temas', style: TextStyle(color: Colors.white)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orange),
                minimumSize: const Size(double.infinity, 45), // Ocupa el ancho completo
              ),
              onPressed: () => _showStatsBottomSheet(context),
            ),
          ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Sets deseados',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(child: _buildWishlistList()),
      ],
    );
  }*/
  Widget _buildNarrowLayout() {
    return Column(
      children: [
        // ENCABEZADO ESTILO COLECCIÓN (Box oscuro pegado arriba)
        /*//Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          decoration: const BoxDecoration(
            color: Color(0xFF2A2A2A),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: WishlistSummaryCard(
            totalValue: _totalValue,
            budget: _budget,
            onBudgetUpdated: _loadWishlist,
            // Aquí activamos la visualización de la gráfica si hay sets
            showButton: _wishlistItems.isNotEmpty,
            buttonLabel: 'Ver estadísticas de temas',
            onButtonPressed: () => _showStatsBottomSheet(context),
          ),
        //),*/
        WishlistSummaryCard(
          totalValue: _totalValue,
          budget: _budget,
          onBudgetUpdated: _loadWishlist,
          showButton: _wishlistItems.isNotEmpty,
          buttonLabel: 'Ver estadísticas de temas',
          onButtonPressed: () => _showStatsBottomSheet(context),
        ),
        
        const SizedBox(height: 16),
        
        // --- TEXTO DE LA LISTA ---
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Sets deseados',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        
        const SizedBox(height: 10),
        
        // --- LA LISTA ORIGINAL (No hace falta tocar el ListView) ---
        Expanded(child: _buildWishlistList()),
      ],
    );
  }

  // --- NUEVA FUNCIÓN PARA EL BOTTOM SHEET ---
  void _showStatsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Ajusta el tamaño al contenido
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              WishlistThemeChartWidget(themeData: _getThemeDistribution()),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWideLayout() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // COLUMNA IZQUIERDA: RESUMEN FINANCIERO (40%)
          Expanded(
            flex: 4,
            child: Column(
              children: [
                WishlistSummaryCard(
                  totalValue: _totalValue,
                  budget: _budget,
                  onBudgetUpdated: _loadWishlist,
                ),
                const SizedBox(height: 24),
                // --- NUEVO GRÁFICO AQUÍ ---
                if (_wishlistItems.isNotEmpty)
                  WishlistThemeChartWidget(themeData: _getThemeDistribution()),
              ],
            ),
          ),
          
          const SizedBox(width: 40),

          // COLUMNA DERECHA: LISTA DE DESEADOS (60%)
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mi Lista de Deseos',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Expanded(child: _buildWishlistList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // LISTA DE ELEMENTOS (Corregida con tus datos reales)
  // ===========================================================================

  Widget _buildWishlistList() {
    if (_wishlistItems.isEmpty) {
      return const Center(
        child: Text('Tu lista de deseos está vacía', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: _wishlistItems.length,
      itemBuilder: (context, index) {
        final item = _wishlistItems[index];
        final double targetPrice = (item['targetPrice'] as num).toDouble();

        return Card(
          color: const Color(0xFF1E1E1E), 
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 60,
                height: 60,
                color: Colors.white,
                child: CachedNetworkImage(
                  imageUrl: _getImageUrl(item['imgUrl']),
                  fit: BoxFit.contain,
                  errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
            title: Text(
              item['name'],
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Set #${item['setNum']} • ${item['numParts'] ?? '?'} pz', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  '$targetPrice €',
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              // AQUÍ USAMOS TU MÉTODO Y TU ID DE MONGODB
              onPressed: () => _removeSet(item['id']),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SetDetailsScreen(
                    legoSet: LegoSet(
                      setNum: item['setNum'],
                      name: item['name'],
                      numParts: item['numParts'] ?? 0,
                      imgUrl: item['imgUrl'],
                      year: item['year'] ?? 0,
                      themeId: item['themeId'] ?? 0,
                    ),
                  ),
                ),
              ).then((_) => _loadWishlist());
            },
          ),
        );
      },
    );
  }

  // LLAMANDO A TU API SERVICE CORRECTAMENTE
  Future<void> _removeSet(String id) async {
    final success = await _apiService.deleteFromWishlist(id);
    if (success) {
      _loadWishlist();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eliminado de deseados'), backgroundColor: Colors.orange),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Deseos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.orange),
            onPressed: _loadWishlist,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 900) {
                  return _buildWideLayout();
                } else {
                  return _buildNarrowLayout();
                }
              },
            ),
    );
  }
}