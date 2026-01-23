import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';
import '../models/lego_theme.dart';
import '../models/lego_set.dart';
import '../services/api_service.dart';

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
                  child: FadeInImage.memoryNetwork(
                    placeholder: kTransparentImage,
                    image: set.imgUrl,
                    fit: BoxFit.contain,
                    imageErrorBuilder: (context, error, stackTrace) => 
                        const Icon(Icons.broken_image),
                  ),
                ),
                title: Text(
                  set.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('#${set.setNum} | ${set.year}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Ir al detalle del set
                  print("Click en set: ${set.setNum}");
                },
              );
            },
          );
        },
      ),
    );
  }
}