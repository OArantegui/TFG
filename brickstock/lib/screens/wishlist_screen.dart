import 'package:flutter/material.dart';
import '../models/lego_set.dart';
import '../services/api_service.dart';
import 'set_details_screen.dart';
import '../widgets/wishlist_summary_card.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  late Future<Map<String, dynamic>> _wishlistFuture;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  void _loadWishlist() {
    setState(() {
      _wishlistFuture = ApiService().getWishlistData();
    });
  }

  void _editBudget(double currentBudget) {
    TextEditingController controller = TextEditingController(
      text: currentBudget.toStringAsFixed(0),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajustar Presupuesto'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Presupuesto Máximo (€)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              double? newBudget = double.tryParse(controller.text);
              if (newBudget != null) {
                await ApiService().updateWishlistBudget(newBudget);
                Navigator.pop(ctx);
                _loadWishlist(); // Recargar para ver los cambios
              }
            },
            child: const Text(
              'Guardar',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // AÑADIDO: Scaffold nativo idéntico al de CollectionScreen
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis Deseados'
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.orange),
            onPressed: _loadWishlist,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _wishlistFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          } else if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error al cargar la lista',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final data = snapshot.data!;
          final budget = (data['budget'] as num).toDouble();
          final List items = data['data'];

          // Calcular total
          double totalValue = items.fold(
            0,
            (sum, item) => sum + (item['targetPrice'] as num).toDouble(),
          );

          return Column(
            children: [
              WishlistSummaryCard(
                totalValue: totalValue,
                budget: budget,
                onBudgetUpdated: _loadWishlist, // Carga la lista
              ),

              if (items.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'Tu lista de deseados está vacía',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                )
              else
                // LISTA DE SETS DESEADOS
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Card(
                        color: const Color(0xFF2A2A2A),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16.0, // Alineado con los márgenes habituales
                          vertical: 6.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12.0),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6.0),
                            child: Container(
                              width: 60, height: 60, color: Colors.white,
                              child: Image.network(
                                ApiService().getProxyUrl(item['imgUrl']),
                                fit: BoxFit.contain,
                                errorBuilder: (ctx, err, stack) => const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            item['name'],
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            maxLines: 2, 
                            overflow: TextOverflow.ellipsis
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Set: ${item['setNum']} • ${item['numParts'] ?? '?'} pz',
                                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                                Text(
                                  'Objetivo: ${item['targetPrice']} €',
                                  style: const TextStyle(color: Colors.orange, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            onPressed: () async {
                              await ApiService().deleteFromWishlist(item['id']);
                              _loadWishlist();
                            },
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SetDetailsScreen(
                                  legoSet: LegoSet(
                                    setNum: item['setNum'],
                                    name: item['name'],
                                    numParts: item['numParts'],
                                    imgUrl: item['imgUrl'],
                                    year: item['year'],
                                    themeId: item['themeId'],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}