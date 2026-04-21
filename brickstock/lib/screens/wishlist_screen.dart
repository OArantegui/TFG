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

  Widget _buildNarrowLayout() {
    return Column(
      children: [
        const SizedBox(height: 16),
        WishlistSummaryCard(
          totalValue: _totalValue,
          budget: _budget,
          onBudgetUpdated: _loadWishlist,
          showButton: _wishlistItems.isNotEmpty,
          buttonLabel: 'Estadística por temas',
          onButtonPressed: () => _showStatsDialog(context),
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

  
  // --- NUEVA FUNCIÓN PARA EL MODAL CENTRADO (ESTILO COLECCIÓN) ---
  void _showStatsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Estadística por temas', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        content: SizedBox(
          width: 400, // Misma proporción que en tu historial de mercado
          child: SingleChildScrollView(
            child: WishlistThemeChartWidget(themeData: _getThemeDistribution()),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('Cerrar', style: TextStyle(color: Colors.orange))
          ),
        ],
      ),
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
                const SizedBox(height: 30),
                const Text('Estadística por Temas', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
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
              icon: const Icon(Icons.delete, color: Colors.redAccent),
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