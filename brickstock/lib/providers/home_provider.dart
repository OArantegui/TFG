import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/lego_set.dart';

class HomeProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Variables de estado renombradas para mayor claridad
  List<LegoSet> newReleaseSets = [];
  bool isLoading = true;
  String? errorMessage;

  // Al crear el provider, lanzamos la carga automáticamente
  HomeProvider() {
    loadNewReleases();
  }

  Future<void> loadNewReleases() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners(); // Avisamos a la UI que estamos cargando

      // O(1) Petición: Obtenemos la primera página de todos los sets.
      // El backend ya los ordena por '-year' por defecto.
      final response = await _apiService.getAllSets(page: 1);
      final List<LegoSet> allSets = response['sets'] as List<LegoSet>;

      // Guardamos resultados en el estado (solo los 10 primeros)
      newReleaseSets = allSets.take(10).toList();
      
    } catch (e) {
      errorMessage = 'Error al cargar las novedades: $e';
      debugPrint(errorMessage);
    } finally {
      // Finalizamos la carga
      isLoading = false;
      notifyListeners(); // Avisamos a la UI que ya hay datos
    }
  }
}