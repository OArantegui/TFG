import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // <--- IMPORTANTE: Para caché e imágenes en web
import 'package:flutter/foundation.dart'; // <--- IMPORTANTE: Para kIsWeb
import '../services/api_service.dart';
import '../models/lego_set.dart';
import 'set_details_screen.dart'; // Para poder navegar al detalle si quieres

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService apiService = ApiService();
  late Future<List<LegoSet>> futureFeaturedSets;

  @override
  void initState() {
    super.initState();
    // TRUCO: Para la portada, cargamos un tema popular fijo (158 = Star Wars)
    futureFeaturedSets = apiService.getSetsByTheme(158);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TÍTULO DEL DASHBOARD
          const Text(
            'PANEL DE CONTROL',
            style: TextStyle(
              letterSpacing: 1.5,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Bienvenido de nuevo',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.1,
            ),
          ),

          const SizedBox(height: 30),

          // 2. SECCIÓN DE DESTACADOS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DESTACADOS (Star Wars)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Ver todos',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 3. CARRUSEL HORIZONTAL DE SETS
          Expanded(
            child: FutureBuilder<List<LegoSet>>(
              future: futureFeaturedSets,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No hay sets destacados'));
                }

                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: snapshot.data!.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final set = snapshot.data![index];
                    // Pasamos el set al widget de tarjeta
                    return _FeaturedSetCard(legoSet: set);
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// --- WIDGET TARJETA DE SET (ACTUALIZADO CON LÓGICA DE IMAGEN) ---
class _FeaturedSetCard extends StatelessWidget {
  final LegoSet legoSet;

  const _FeaturedSetCard({required this.legoSet});

  // --- FUNCIÓN DE "FONTANERÍA" PARA IMÁGENES ---
  // Esta es la misma lógica que usamos en la lista.
  String _getImageUrl(String originalUrl) {
    if (kIsWeb) {
      // Si es Web -> Usamos el Proxy del Backend para saltar CORS
      final encodedUrl = Uri.encodeComponent(originalUrl);
      return 'http://localhost:3000/api/lego/image-proxy?url=$encodedUrl';
    }
    // Si es App -> Directo (más rápido)
    return originalUrl;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Hacemos que la tarjeta sea clicable para ir al detalle
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SetDetailsScreen(legoSet: legoSet),
          ),
        );
      },
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGEN DEL SET (CON CACHED NETWORK IMAGE)
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: _getImageUrl(
                      legoSet.imgUrl,
                    ), // <--- USO DE LA FUNCIÓN
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.orange,
                      ),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 40,
                      ),
                    ),
                  ),
                  // Gradiente para legibilidad
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                          stops: const [0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // TEXTOS
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Etiqueta naranja con el número
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '#${legoSet.setNum}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          legoSet.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    // Datos técnicos (Año y Piezas)
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${legoSet.year}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.extension,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${legoSet.numParts} pcs',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
