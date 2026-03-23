import 'package:flutter/material.dart';
import '../models/collection_item.dart';
import '../services/api_service.dart';
import '../models/lego_set.dart';
import 'set_details_screen.dart'; // Asumiendo que existe

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  late Future<List<CollectionItem>> _collectionFuture;

  @override
  void initState() {
    super.initState();
    _loadCollection();
  }

  void _loadCollection() {
    setState(() {
      _collectionFuture = ApiService().getUserCollection();
    });
  }

  void _deleteItem(String id) async {
    final success = await ApiService().deleteFromCollection(id);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Set eliminado correctamente')),
        );
      }
      _loadCollection(); // Recargamos la lista
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CollectionItem>>(
      future: _collectionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.orange),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'Tu colección está vacía',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final collection = snapshot.data!;

        // Calcular el valor total (Cantidad * Precio Actual)
        final totalValue = collection.fold<double>(
          0,
          (sum, item) => sum + (item.currentPrice * item.quantity),
        );

        return Column(
          children: [
            // Panel superior de resumen financiero (Anti-diseño: Simple Container con Text)
            Container(
              padding: const EdgeInsets.all(16.0),
              color: const Color(0xFF2A2A2A),
              width: double.infinity,
              child: Column(
                children: [
                  const Text(
                    'Valor Total de Colección',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${totalValue.toStringAsFixed(2)} €',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Lista de Sets
            Expanded(
              child: ListView.builder(
                itemCount: collection.length,
                itemBuilder: (context, index) {
                  final item = collection[index];
                  return Card(
                    color: const Color(0xFF2A2A2A),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    child: ListTile(
                      leading: Image.network(
                        ApiService().getProxyUrl(
                          item.imgUrl,
                        ), // Usamos tu proxy para imágenes
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                      title: Text(
                        item.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Set: ${item.setNum} • ${item.numParts} pz\nValor: ${item.currentPrice.toStringAsFixed(2)} €',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _deleteItem(item.id), // Borrar
                      ),
                      onTap: () {
                        // Navegación a la pantalla de detalles pasando el objeto esperado
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SetDetailsScreen(
                              legoSet: LegoSet(
                                setNum: item.setNum,
                                name: item.name,
                                numParts: item.numParts,
                                imgUrl: item.imgUrl,
                                // Como estos datos no los guardamos en la colección financiera,
                                // pasamos valores por defecto o cero. La pantalla de detalles
                                // seguramente ya los pida al backend si los necesita.
                                year: 0,
                                themeId: 0,
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
