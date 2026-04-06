import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/collection_item.dart';
import '../models/minifigure.dart';

class CollectionProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<CollectionItem> _collection = [];
  List<Minifigure> _minifigs = [];

  bool _isLoading = false;

  // TFG: Variable para almacenar el Future de los datos de mercado globales
  Future<Map<String, dynamic>?>? _collectionMarketDataFuture;

  List<CollectionItem> get collection => _collection;
  List<Minifigure> get minifigs => _minifigs;
  bool get isLoading => _isLoading;

  Future<Map<String, dynamic>?>? get collectionMarketDataFuture => _collectionMarketDataFuture;

  double get totalCollectionValue {
    return _collection.fold(
      0.0,
      (sum, item) => sum + (item.purchasePrice * item.quantity),
    );
  }

  int get totalSets {
    return _collection.fold(0, (sum, item) => sum + item.quantity);
  }

  int get totalMinifigures {
    return _minifigs.fold(0, (sum, item) => sum + item.quantity);
  }

  Future<void> loadCollection({bool forceRefresh = false}) async {
    if (_collection.isNotEmpty && _minifigs.isNotEmpty && !forceRefresh) {
      return; //evita recargas innesaria en coleccion
    }
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _apiService.getUserCollection(),
        _apiService.getUserMinifigCollection(),
      ]);

      _collection = results[0] as List<CollectionItem>;
      _minifigs = results[1] as List<Minifigure>;

      _collectionMarketDataFuture = _apiService.getCollectionMarketData();
    } catch (e) {
      debugPrint('Error al cargar la cartera completa: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteFromCollection(String id) async {
    // 1. Mandamos la orden al backend (Node.js borrará el set y sus minifiguras)
    bool success = await _apiService.deleteFromCollection(id);
    
    if (success) {
      // 2. Borramos el set visualmente de la lista de Flutter al instante
      _collection.removeWhere((item) => item.id == id);

      // SINCRONIZACIÓN SILENCIOSA DE MINIFIGURAS 
      // Como Node.js ha alterado las minifiguras por detrás, pedimos 
      // la nueva lista actualizada de minifiguras y la sobreescribimos
      // sin mostrar círculos de carga molestos.
      try {
        _minifigs = await _apiService.getUserMinifigCollection();
      } catch (e) {
        debugPrint('Error sincronizando minifiguras tras borrar set: $e');
      }

      // 3. Recalculamos la gráfica de mercado global porque hay un set menos
      _collectionMarketDataFuture = _apiService.getCollectionMarketData();
      
      // 4. Avisamos a la interfaz para que se repinte entera (incluyendo el contador nuevo)
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
