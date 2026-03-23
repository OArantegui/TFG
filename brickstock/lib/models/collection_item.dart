class CollectionItem {
  final String id;
  final String setNum;
  final String name;
  final int numParts;
  final String imgUrl;
  final int quantity;
  final double purchasePrice;
  final double currentPrice;

  CollectionItem({
    required this.id,
    required this.setNum,
    required this.name,
    required this.numParts,
    required this.imgUrl,
    required this.quantity,
    required this.purchasePrice,
    required this.currentPrice,
  });

  factory CollectionItem.fromJson(Map<String, dynamic> json) {
    return CollectionItem(
      id: json['id'],
      setNum: json['setNum'],
      name: json['name'],
      numParts: json['numParts'],
      imgUrl: json['imgUrl'],
      quantity: json['quantity'],
      // Hacemos cast a double para evitar errores si Node manda un int
      purchasePrice: (json['purchasePrice'] as num).toDouble(),
      currentPrice: (json['currentPrice'] as num).toDouble(),
    );
  }
}
