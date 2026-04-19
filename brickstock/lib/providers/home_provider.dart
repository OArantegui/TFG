import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/lego_set.dart';

class HomeProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Variables de estado renombradas para mayor claridad
  List<LegoSet> featuredSets = [];
  bool isLoading = true;
  String? errorMessage;

  // Al crear el provider, lanzamos la carga automáticamente
  HomeProvider() {
    loadRecommendations();
  }

  Future<void> refresh() async {
    await loadRecommendations();
  }

  Future<void> loadRecommendations() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      List<int> userThemeIds = [];
      List<String> userSetNums = [];

      try {
        final response = await _apiService.getWishlistData();

        final List<dynamic> items =
            response['data'] ?? response['items'] ?? response['wishlist'] ?? [];

        for (var item in items) {
          final setNum =
              item['setNum'] ??
              (item['set'] != null ? item['set']['set_num'] : null);
          if (setNum != null) userSetNums.add(setNum);

          int themeId =
              item['themeId'] ??
              (item['set'] != null ? item['set']['theme_id'] ?? 0 : 0);
          if (themeId != 0) userThemeIds.add(themeId);
        }
      } catch (e) {
        debugPrint("No se pudo obtener la wishlist: $e");
      }

      if (userThemeIds.isNotEmpty) {
        final themeCounts = <int, int>{};
        for (var tId in userThemeIds) {
          themeCounts[tId] = (themeCounts[tId] ?? 0) + 1;
        }

        final favoriteThemeId = themeCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;

        final responseSets = await _apiService.getAllSets(page: 1);
        final List<LegoSet> allSets = responseSets['sets'] as List<LegoSet>;

        featuredSets = allSets
            .where(
              (s) =>
                  s.themeId == favoriteThemeId &&
                  !userSetNums.contains(s.setNum),
            )
            .take(10)
            .toList();
      }

      if (featuredSets.isEmpty) {
        final responseSets = await _apiService.getAllSets(page: 1);
        final List<LegoSet> allSets = responseSets['sets'] as List<LegoSet>;
        featuredSets = allSets.take(10).toList();
      }
    } catch (e) {
      errorMessage = 'Error al cargar recomendaciones: $e';
      debugPrint(errorMessage);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
