import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/lego_set.dart';
import '../models/lego_theme.dart';
import 'set_details_screen.dart';
import 'sets_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService apiService = ApiService();

  // Controlador para las flechas de navegación
  final ScrollController _scrollController = ScrollController();

  Future<List<LegoSet>>? futureFeaturedSets;

  // Si es null, significa que estamos en modo "Mix Aleatorio"
  LegoTheme? featuredTheme;

  @override
  void initState() {
    super.initState();
    _loadMixedFeaturedSets();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // --- NUEVA LÓGICA: CARGAR MIX DE DIFERENTES CATÁLOGOS ---
  Future<void> _loadMixedFeaturedSets() async {
    try {
      // 1. Obtenemos todos los temas disponibles
      final themes = await apiService.getThemes();

      if (themes.isNotEmpty) {
        // 2. Barajamos y cogemos 10 temas distintos
        // (Cogemos 12 por seguridad, por si alguno viniera vacío)
        themes.shuffle();
        final selectedThemes = themes.take(12).toList();

        // 3. Preparamos una lista de "Futuros" para pedirlos todos a la vez (paralelo)
        // Esto es mucho más rápido que pedir uno a uno.
        final futures = selectedThemes.map(
          (t) => apiService.getSetsByTheme(t.id),
        );

        // 4. Esperamos a que lleguen todos los datos
        final results = await Future.wait(futures);

        // 5. Construimos la lista final cogiendo el PRIMER set de cada tema
        final List<LegoSet> mixedList = [];
        for (var setList in results) {
          if (setList.isNotEmpty) {
            mixedList.add(setList.first);
          }
        }

        // 6. Actualizamos la pantalla (limitamos a 10 para que quede redondo)
        setState(() {
          featuredTheme = null; // null indica que es un Mix
          futureFeaturedSets = Future.value(mixedList.take(10).toList());
        });
      }
    } catch (e) {
      debugPrint('Error cargando mix aleatorio: $e');
    }
  }

  // Función para mover el scroll con las flechas
  void _scrollList(double offset) {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.offset + offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER
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

          // 2. TÍTULO Y CONTROLES
          Row(
            children: [
              Expanded(
                child: Text(
                  // Si featuredTheme es null, mostramos título genérico
                  featuredTheme != null
                      ? 'DESTACADOS (${featuredTheme!.name})'
                      : 'DESTACADOS',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Flechas de navegación manual
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  size: 16,
                  color: Colors.white70,
                ),
                onPressed: () => _scrollList(-220),
                tooltip: "Anterior",
              ),
              IconButton(
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.white70,
                ),
                onPressed: () => _scrollList(220),
                tooltip: "Siguiente",
              ),

              const SizedBox(width: 8),

              // Botón "Ver todos"
              // Solo se muestra si hay un tema específico seleccionado.
              // En el modo Mix lo ocultamos porque no hay "un catálogo" que ver.
              if (featuredTheme != null)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SetsListScreen(theme: featuredTheme!),
                      ),
                    );
                  },
                  child: const Text(
                    'Ver todos',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // 3. CARRUSEL
          Expanded(
            child: futureFeaturedSets == null
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  )
                : FutureBuilder<List<LegoSet>>(
                    future: futureFeaturedSets,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.orange,
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('No hay sets destacados'),
                        );
                      }

                      return ListView.separated(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: snapshot.data!.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          return _FeaturedSetCard(
                            legoSet: snapshot.data![index],
                          );
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

// --- TARJETA DE SET ---
class _FeaturedSetCard extends StatelessWidget {
  final LegoSet legoSet;

  const _FeaturedSetCard({required this.legoSet});

  String _getImageUrl(String originalUrl) {
    if (kIsWeb) {
      final encodedUrl = Uri.encodeComponent(originalUrl);
      return 'http://localhost:3000/api/lego/image-proxy?url=$encodedUrl';
    }
    return originalUrl;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
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
            // Imagen
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: _getImageUrl(legoSet.imgUrl),
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

            // Textos
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
