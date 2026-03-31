class Minifigure {
  final String figNum;
  final String name;
  final String imageUrl;
  final int quantity;

  Minifigure({
    required this.figNum,
    required this.name,
    required this.imageUrl,
    required this.quantity,
  });

  factory Minifigure.fromJson(Map<String, dynamic> json) {
    return Minifigure(
      figNum: json['figNum'] ?? '',
      name: json['name'] ?? 'Desconocido',
      imageUrl: json['imageUrl'] ?? '',
      quantity: json['quantity'] ?? 1,
    );
  }
}