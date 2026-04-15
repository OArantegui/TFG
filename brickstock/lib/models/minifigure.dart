class Minifigure {
  final String? id; // ID de nuestra BBDD
  final String figNum;
  final String name;
  final String imageUrl;
  final int quantity;
  final int numParts;
  final String? source; // 'From Set' o 'Manual'
  final String? sourceSetNum; // Si vino de un set, ¿de cuál?

  Minifigure({
    this.id,
    required this.figNum,
    required this.name,
    required this.imageUrl,
    required this.quantity,
    this.numParts = 0,
    this.source,
    this.sourceSetNum,
  });

  factory Minifigure.fromJson(Map<String, dynamic> json) {
    // Mapeamos los datos dependiendo de si vienen de Rebrickable o de nuestra bbdd
    return Minifigure(
      id: json['_id'] ?? json['id'],
      figNum: json['figNum'] ?? json['set_num'] ?? '',
      name: json['name'] ?? 'Desconocido',
      imageUrl: json['imageUrl'] ?? json['set_img_url'] ?? '',
      quantity: json['quantity'] ?? 1,
      numParts: json['numParts'] ?? json['num_parts'] ?? 0,
      source: json['source'],
      sourceSetNum: json['sourceSetNum'],
    );
  }
}