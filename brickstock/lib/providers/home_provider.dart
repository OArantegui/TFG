import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/lego_set.dart';
import '../models/lego_theme.dart';

class HomeProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Variables de estado
  List<LegoSet> featuredSets = [];
  LegoTheme? featuredTheme;
  bool isLoading = true;
  String? errorMessage;

  // Al crear el provider, lanzamos la carga automáticamente
  HomeProvider() {
    loadMixedFeaturedSets();
  }

  Future<void> loadMixedFeaturedSets() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners(); // Avisamos a la UI que estamos cargando

      // 1. Pedimos los temas
      final response = await _apiService.getThemes();
      final List<dynamic> themeData = response['results'];

      // 2. Mapeamos
      final List<LegoTheme> themes = themeData.map((e) => LegoTheme(
        id: e['id'],
        name: e['name'],
        parentId: e['parent_id']
      )).toList();

      if (themes.isNotEmpty) {
        // 3. Barajamos y preparamos las peticiones simultáneas
        themes.shuffle();
        final selectedThemes = themes.take(12).toList();
        final futures = selectedThemes.map((t) => _apiService.getSetsByTheme(t.id));
        
        // 4. Ejecutamos todas a la vez
        final resultsList = await Future.wait(futures);

        final List<LegoSet> mixedList = [];
        for (var resultMap in resultsList) {
          final List<LegoSet> setList = resultMap['sets'] as List<LegoSet>;
          if (setList.isNotEmpty) {
            mixedList.add(setList.first);
          }
        }

        // 5. Guardamos resultados en el estado
        featuredTheme = null;
        featuredSets = mixedList.take(10).toList();
      }
    } catch (e) {
      errorMessage = 'Error al cargar los sets: $e';
      debugPrint(errorMessage);
    } finally {
      // 6. Finalizamos la carga
      isLoading = false;
      notifyListeners(); // Avisamos a la UI que ya hay datos
    }
  }
}