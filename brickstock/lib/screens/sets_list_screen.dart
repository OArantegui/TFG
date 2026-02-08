import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb
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

  // --- FUNCIÓN CORREGIDA Y REUTILIZADA ---
  String _getImageUrl(String? originalUrl) {
    // 1. Si no hay imagen, devolvemos una cadena vacía (lo gestionaremos abajo)
    if (originalUrl == null || originalUrl.isEmpty) {
      return '';
    }

    // 2. Si es Web, usamos la función centralizada del ApiService (IGUAL QUE EN EXPLORE)
    if (kIsWeb) {
      return apiService.getProxyUrl(originalUrl);
    }

    // 3. Si es Móvil, usamos la original
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
              // Obtenemos la URL correcta (Proxy o Directa)
              final finalImageUrl = _getImageUrl(set.imgUrl);

              return ListTile(
                contentPadding: const EdgeInsets.all(8),
                leading: SizedBox(
                  width: 80,
                  height: 80,
                  child: finalImageUrl.isEmpty
                      ? const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        )
                      : CachedNetworkImage(
                          imageUrl: finalImageUrl,
                          memCacheWidth: 200,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (context, url, error) {
                            // Si falla la carga, mostramos icono roto
                            return const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                            );
                          },
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
