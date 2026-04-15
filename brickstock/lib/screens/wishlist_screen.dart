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
    return FutureBuilder<Map<String, dynamic>>(
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

        // Lógica de progreso
        double progress = budget > 0 ? totalValue / budget : 0.0;
        bool isOverBudget = progress > 1.0;
        Color statusColor = isOverBudget ? Colors.redAccent : Colors.orange;

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
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: ListTile(
                        leading: Image.network(
                          ApiService().getProxyUrl(item['imgUrl']),
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        ),
                        title: Text(
                          item['name'],
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          'Set: ${item['setNum']} • ${item['targetPrice']} €',
                          style: const TextStyle(color: Colors.grey),
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
    );
  }
}
