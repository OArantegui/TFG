import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/lego_set.dart';
import '../models/lego_theme.dart';
import '../providers/home_provider.dart';
import 'set_details_screen.dart';
import 'sets_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  // Constante para evitar "Magic Numbers"
  static const double _scrollOffset = 220.0; 

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollList(double multiplier) {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.offset + (_scrollOffset * multiplier),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos context.watch para re-dibujar solo cuando el Provider llame a notifyListeners()
    final provider = context.watch<HomeProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          // TÍTULO Y CONTROLES
          Row(
            children: [
              Expanded(
                child: Text(
                  provider.featuredTheme != null
                      ? 'DESTACADOS (${provider.featuredTheme!.name})'
                      : 'DESTACADOS',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 16, color: Colors.white70),
                onPressed: () => _scrollList(-1),
                tooltip: "Anterior",
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white70),
                onPressed: () => _scrollList(1),
                tooltip: "Siguiente",
              ),
              const SizedBox(width: 8),

              if (provider.featuredTheme != null)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SetsListScreen(theme: provider.featuredTheme!),
                      ),
                    );
                  },
                  child: const Text('Ver todos', style: TextStyle(color: Colors.grey)),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // CARRUSEL
          Expanded(
            child: _buildCarouselContent(provider),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Extraemos el IF de estados a un método para que el build principal no quede sucio
  Widget _buildCarouselContent(HomeProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.orange));
    }
    
    if (provider.errorMessage != null) {
      return Center(
        child: Text(
          provider.errorMessage!,
          style: const TextStyle(color: Colors.redAccent),
        ),
      );
    }

    if (provider.featuredSets.isEmpty) {
      return const Center(child: Text('No hay sets destacados'));
    }

    return ListView.separated(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: provider.featuredSets.length,
      separatorBuilder: (context, index) => const SizedBox(width: 16),
      itemBuilder: (context, index) {
        return _FeaturedSetCard(legoSet: provider.featuredSets[index]);
      },
    );
  }
}

// TARJETA DE SET
class _FeaturedSetCard extends StatelessWidget {
  final LegoSet legoSet;

  const _FeaturedSetCard({required this.legoSet});

  // Función refactorizada aplicando DRY
  String _getImageUrl(String originalUrl) {
    if (kIsWeb) {
      // Usamos el servicio centralizado que sabe si estamos en Local o Producción
      return ApiService().getProxyUrl(originalUrl);
    }
    return originalUrl;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // al hacer click, nos movemos a la pantalla Details
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
                //Stack nos permite poner cosas encima de otras
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
