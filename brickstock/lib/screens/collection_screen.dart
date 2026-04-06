import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/collection_provider.dart';
import '../services/api_service.dart';
import '../models/minifigure.dart';
import '../models/lego_set.dart';
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

  @override
  void initState() {
    super.initState();
    // Cargamos los datos nada más entrar a la pantalla
    Future.microtask(() => Provider.of<CollectionProvider>(context, listen: false).loadCollection());
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CollectionProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: const Text('Mi Colección', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.orange),
            onPressed: () => provider.loadCollection(),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Column(
              children: [
                // PANEL SUPERIOR: Valor Total (Izq) | Minifiguras (Der)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: const Color(0xFF2A2A2A),
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Izquierda: Valor Total
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('VALOR TOTAL', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          const SizedBox(height: 5),
                          Text('${provider.totalCollectionValue.toStringAsFixed(2)} €', style: const TextStyle(color: Colors.orange, fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      // Derecha: Cantidad de Minifiguras
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('MINIFIGURAS', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          const SizedBox(height: 5),
                          Text('${provider.totalMinifigures}', style: const TextStyle(color: Colors.orange, fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // TOGGLE NATIVO MATERIAL 3
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SegmentedButton<CollectionMode>(
                    style: SegmentedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D2D2D),
                      foregroundColor: Colors.white,
                      selectedForegroundColor: Colors.white,
                      selectedBackgroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.white10),
                    ),
                    segments: const [
                      ButtonSegment(value: CollectionMode.sets, label: Text('Sets'), icon: Icon(Icons.inventory_2)),
                      ButtonSegment(value: CollectionMode.minifigs, label: Text('Minifiguras'), icon: Icon(Icons.smart_toy)),
                    ],
                    selected: {_selectedMode},
                    onSelectionChanged: (Set<CollectionMode> newSelection) {
                      setState(() {
                        _selectedMode = newSelection.first;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 10),

                // LISTA DINÁMICA
                Expanded(
                  child: _selectedMode == CollectionMode.sets 
                      ? _buildSetsList(provider) 
                      : _buildMinifigsList(provider),
                ),
              ],
            ),
    );
  }

  // ==========================================
  // VISTA 1: LISTA DE SETS
  // ==========================================
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12.0),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6.0),
              child: Container(
                width: 60, height: 60, color: Colors.white,
                child: CachedNetworkImage(
                  imageUrl: ApiService().getProxyUrl(item.imgUrl),
                  fit: BoxFit.contain,
                  errorWidget: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
            title: Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ¡Añadimos el nombre del tema aquí!
                  Text(item.themeName.toUpperCase(), style: const TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text('Set: ${item.setNum} • ${item.numParts} pz', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  Text('Cantidad: ${item.quantity} • ${item.purchasePrice}€', style: const TextStyle(color: Colors.orange, fontSize: 13)),
                ],
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _confirmDeleteSet(context, provider, item.id),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SetDetailsScreen(
                    legoSet: LegoSet(
                      setNum: item.setNum, name: item.name, numParts: item.numParts,
                      imgUrl: item.imgUrl, year: item.year, themeId: item.themeId,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ==========================================
  // VISTA 2: LISTA DE MINIFIGURAS
  // ==========================================
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12.0),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6.0),
              child: Container(
                width: 60, height: 60, color: Colors.white,
                child: CachedNetworkImage(
                  imageUrl: ApiService().getProxyUrl(fig.imageUrl),
                  fit: BoxFit.contain,
                  errorWidget: (context, url, error) => const Icon(Icons.face, color: Colors.black),
                ),
              ),
            ),
            title: Text(fig.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ID: ${fig.figNum}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  Text('Cantidad: ${fig.quantity}', style: const TextStyle(color: Colors.orange, fontSize: 13)),
                  if (fig.source == 'From Set' && fig.sourceSetNum != null)
                    Text('Del set: ${fig.sourceSetNum}', style: const TextStyle(color: Colors.greenAccent, fontSize: 11)),
                ],
              ),
            ),
            // ICONO DE PAPELERA INDIVIDUAL
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _confirmDeleteMinifig(context, provider, fig),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MinifigDetailsScreen(minifigure: fig),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ==========================================
  // CUADROS DE DIÁLOGO DE CONFIRMACIÓN
  // ==========================================
  void _confirmDeleteSet(BuildContext context, CollectionProvider provider, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('Eliminar Set', style: TextStyle(color: Colors.white)),
        content: const Text('¿Seguro que quieres eliminar este set de tu cartera?', style: TextStyle(color: Colors.white70)),
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
        content: const Text('¿Seguro que quieres eliminar esta minifigura de tu cartera?', style: TextStyle(color: Colors.white70)),
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