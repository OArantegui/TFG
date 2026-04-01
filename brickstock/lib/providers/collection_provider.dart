import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/collection_item.dart';
import '../models/minifigure.dart'; 

class CollectionProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<CollectionItem> _collection = [];
  List<Minifigure> _minifigs = []; 

  bool _isLoading = false;

  List<CollectionItem> get collection => _collection;
  List<Minifigure> get minifigs => _minifigs;
  bool get isLoading => _isLoading;

  double get totalCollectionValue {
    return _collection.fold(0.0, (sum, item) => sum + (item.purchasePrice * item.quantity));
  }

  int get totalSets {
    return _collection.fold(0, (sum, item) => sum + item.quantity);
  }

  int get totalMinifigures {
    return _minifigs.fold(0, (sum, item) => sum + item.quantity);
  }

  Future<void> loadCollection() async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _apiService.getUserCollection(),
        _apiService.getUserMinifigCollection(),
      ]);

      _collection = results[0] as List<CollectionItem>;
      _minifigs = results[1] as List<Minifigure>;
    } catch (e) {
      debugPrint('Error al cargar la cartera completa: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteFromCollection(String id) async {
    bool success = await _apiService.deleteFromCollection(id);
    if (success) {
      _collection.removeWhere((item) => item.id == id);
      notifyListeners();
    }
    return success;
  }

  Future<bool> deleteMinifig(String id) async {
    bool success = await _apiService.deleteMinifigFromCollection(id);
    if (success) {
      _minifigs.removeWhere((item) => item.id == id);
      notifyListeners();
    }
    return success;
  }
}