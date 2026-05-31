import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/lego_set.dart';
import '../models/collection_item.dart';

class HomeProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<LegoSet> featuredSets = [];
  bool isLoading = true;
  String? errorMessage;

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
        final List<CollectionItem> collection = await _apiService
            .getUserCollection();

        for (var item in collection) {
          userSetNums.add(item.setNum);
          if (item.themeId != 0) {
            userThemeIds.add(item.themeId);
          }
        }
      } catch (e) {
        debugPrint("Error leyendo colección: $e");
      }

      if (userThemeIds.isNotEmpty) {
        final themeCounts = <int, int>{};
        for (var tId in userThemeIds) {
          themeCounts[tId] = (themeCounts[tId] ?? 0) + 1;
        }

        final favoriteThemeId = themeCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;

        debugPrint("Tema favorito detectado ID: $favoriteThemeId");

        final responseSets = await _apiService.getSetsByTheme(
          favoriteThemeId,
          page: 1,
        );
        final List<LegoSet> themeSets = responseSets['sets'] as List<LegoSet>;

        // Filtramos para quitar los que ya tienes
        featuredSets = themeSets
            .where((s) => !userSetNums.contains(s.setNum))
            .take(10)
            .toList();
      }

      if (featuredSets.isEmpty) {
        final responseSets = await _apiService.getAllSets(page: 1);
        final List<LegoSet> allSets = responseSets['sets'] as List<LegoSet>;
        featuredSets = allSets.take(10).toList();
      }
    } catch (e) {
      errorMessage = e.toString();
      debugPrint("Error general en recomendaciones: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
