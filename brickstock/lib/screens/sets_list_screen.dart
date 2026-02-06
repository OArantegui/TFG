import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; //Necesario para las imagenes en memoria
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:transparent_image/transparent_image.dart';
import '../models/lego_theme.dart';
import '../models/lego_set.dart';
import '../services/api_service.dart';
import 'set_details_screen.dart';

class SetsListScreen extends StatefulWidget {
  final LegoTheme theme;

  const SetsListScreen({super.key, required this.theme});

  @override
  State<SetsListScreen> createState() => _SetsListScreenState();
}

class _SetsListScreenState extends State<SetsListScreen> {
  final ApiService apiService = ApiService();
  late Future<List<LegoSet>> futureSets;

  @override
  void initState() {
    super.initState();
    futureSets = apiService.getSetsByTheme(widget.theme.id);
  }

  // Se pone dentro de la clase State, pero FUERA del método build.
  String _getImageUrl(String originalUrl) {
    if (kIsWeb) {
      // Si estamos en Web, le pedimos a TU backend que nos descargue la imagen
      // para evitar el bloqueo de seguridad (CORS) de Rebrickable.
      final encodedUrl = Uri.encodeComponent(originalUrl);
      return 'http://localhost:3000/api/lego/image-proxy?url=$encodedUrl';
    }
    // Si es Android/iOS, la pedimos directa (es más rápido)
    return originalUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.theme.name)),
      body: FutureBuilder<List<LegoSet>>(
        future: futureSets,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay sets en esta colección'));
          }

          final sets = snapshot.data!;

          return ListView.separated(
            itemCount: sets.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final set = sets[index];
              return ListTile(
                contentPadding: const EdgeInsets.all(8),
                leading: SizedBox(
                  width: 80,
                  height: 80,
                  child: CachedNetworkImage(
                    imageUrl: _getImageUrl(
                      set.imgUrl,
                    ), // <--- Aquí usamos la función mágica
                    memCacheWidth: 200, // Optimización de memoria
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.broken_image, color: Colors.grey),
                    fit: BoxFit.contain,
                  ),
                ),
                title: Text(
                  set.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '#${set.setNum} | ${set.year} | ${set.numParts} piezas',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Navegación estándar de Flutter (Push)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SetDetailsScreen(legoSet: set),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
