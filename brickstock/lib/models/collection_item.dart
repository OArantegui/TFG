class CollectionItem {
  final String id;
  final String setNum;
  final String name;
  final int numParts;
  final String imgUrl;
  final int quantity;
  final double purchasePrice;
  final double currentPrice;
  final int year;
  final int themeId;
  final String themeName;

  CollectionItem({
    required this.id,
    required this.setNum,
    required this.name,
    required this.numParts,
    required this.imgUrl,
    required this.quantity,
    required this.purchasePrice,
    required this.currentPrice,
    required this.year,
    required this.themeId,
    required this.themeName,
  });

  factory CollectionItem.fromJson(Map<String, dynamic> json) {
    return CollectionItem(
      id: json['id'] ?? '',
      setNum: json['setNum'] ?? '',
      name: json['name'] ?? 'Desconocido',
      numParts: json['numParts'] ?? 0,
      imgUrl: json['imgUrl'] ?? '',
      quantity: json['quantity'] ?? 1,
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0.0, // Leemos el JSON. Si no viene, ponemos 0 por defecto
      year: json['year'] ?? 0,
      themeId: json['themeId'] ?? 0,
      themeName: json['themeName'] ?? 'Desconocido',
    );
  }
}