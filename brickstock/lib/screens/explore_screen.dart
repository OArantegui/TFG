import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/lego_theme.dart';
import 'sets_list_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final ApiService apiService = ApiService();
  late Future<List<LegoTheme>> futureThemes;

  @override
  void initState() {
    super.initState();
    futureThemes = apiService.getThemes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explorar Colecciones')),
      body: FutureBuilder<List<LegoTheme>>(
        future: futureThemes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay datos'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 columnas
              childAspectRatio: 1.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final theme = snapshot.data![index];
              return _ThemeCard(theme: theme);
            },
          );
        },
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final LegoTheme theme;

  const _ThemeCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SetsListScreen(theme: theme),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias, // Recorta la imagen a los bordes
        elevation: 4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Imagen de fondo (Genérica porque la API no da una)
            Image.network(
              'https://images.unsplash.com/photo-1585366119957-e9730b6d0f60?w=400&q=80', // Foto de legos genérica
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.4), // Oscurecer para leer texto
              colorBlendMode: BlendMode.darken,
            ),
            // 2. Texto encima
            Center(
              child: Text(
                theme.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}