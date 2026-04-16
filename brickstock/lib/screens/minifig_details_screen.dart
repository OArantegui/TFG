import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/minifigure.dart';
import '../models/lego_set.dart';
import '../services/api_service.dart';
import 'set_details_screen.dart';

class MinifigDetailsScreen extends StatefulWidget {
  final Minifigure minifigure;

  const MinifigDetailsScreen({super.key, required this.minifigure});

  @override
  State<MinifigDetailsScreen> createState() => _MinifigDetailsScreenState();
}

class _MinifigDetailsScreenState extends State<MinifigDetailsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<LegoSet> _appearsInSets = [];

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final data = await _apiService.getMinifigDetails(widget.minifigure.figNum);
      
      if (data['appearsInSets'] != null) {
        final List setsData = data['appearsInSets'];
        setState(() {
          _appearsInSets = setsData.map((e) {
            final setInfo = e['set'] ?? e;
            return LegoSet(
              setNum: setInfo['set_num'] ?? e['set_num'] ?? e['setNum'] ?? '',
              name: setInfo['name'] ?? e['name'] ?? 'Desconocido',
              year: setInfo['year'] ?? 0, 
              themeId: setInfo['theme_id'] ?? setInfo['themeId'] ?? 0,
              numParts: setInfo['num_parts'] ?? setInfo['numParts'] ?? 0,
              imgUrl: setInfo['set_img_url'] ?? setInfo['imageUrl'] ?? '',
            );
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error cargando detalles de la minifigura: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addToCollection() async {
    final res = await _apiService.addMinifigToCollection(widget.minifigure.figNum);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']),
          backgroundColor: res['success'] ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles'),
        iconTheme: const IconThemeData(color: Colors.orange),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addToCollection,
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add_circle, color: Colors.white),
        label: const Text('Añadir a Colección', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 250,
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: CachedNetworkImage(
                imageUrl: _apiService.getProxyUrl(widget.minifigure.imageUrl),
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.orange)),
                errorWidget: (context, url, error) => const Icon(Icons.face, size: 100, color: Colors.grey),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.minifigure.name,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Chip(
                        label: Text(widget.minifigure.figNum, style: const TextStyle(color: Colors.white)),
                        backgroundColor: const Color(0xFF2D2D2D),
                        side: BorderSide.none,
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        avatar: const Icon(Icons.extension, color: Colors.orange, size: 16),
                        label: Text('${widget.minifigure.numParts} piezas', style: const TextStyle(color: Colors.white)),
                        backgroundColor: const Color(0xFF2D2D2D),
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white10, height: 1, thickness: 1),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'APARECE EN ${_isLoading ? "..." : _appearsInSets.length} SETS',
                style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
            ),

            _isLoading 
                ? const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator(color: Colors.orange)))
                : _appearsInSets.isEmpty
                    ? const Center(child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Esta minifigura no aparece en ningún set registrado.', style: TextStyle(color: Colors.white54)),
                      ))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(), 
                        itemCount: _appearsInSets.length,
                        itemBuilder: (context, index) {
                          final set = _appearsInSets[index];
                          return Card(
                            color: const Color(0xFF2A2A2A),
                            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(8.0),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(6.0),
                                child: Container(
                                  width: 50, height: 50, color: Colors.white,
                                  child: CachedNetworkImage(
                                    imageUrl: _apiService.getProxyUrl(set.imgUrl),
                                    fit: BoxFit.contain,
                                    errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                                  ),
                                ),
                              ),
                              title: Text(set.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              
                              subtitle: Text(
                                set.year > 0 ? '${set.setNum} • Año: ${set.year}' : 'Set: ${set.setNum}', 
                                style: const TextStyle(color: Colors.white54, fontSize: 12)
                              ),
                              
                              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                              // === TFG: TU LÓGICA MAGISTRAL APLICADA AQUÍ ===
                              onTap: () async {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.orange)),
                                );

                                try {
                                  // Buscamos el set completo (hidratación)
                                  final result = await _apiService.getAllSets(search: set.setNum);
                                  Navigator.pop(context); // Quita el loading

                                  LegoSet fullSet = set; 
                                  if (result['sets'] != null && (result['sets'] as List).isNotEmpty) {
                                    fullSet = (result['sets'] as List).first;
                                  }

                                  Navigator.push(
                                    context, 
                                    MaterialPageRoute(builder: (context) => SetDetailsScreen(legoSet: fullSet))
                                  );
                                } catch (e) {
                                  Navigator.pop(context); // Quita el loading
                                  // Fallback: navegamos con el set incompleto si falla internet
                                  Navigator.push(
                                    context, 
                                    MaterialPageRoute(builder: (context) => SetDetailsScreen(legoSet: set))
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}