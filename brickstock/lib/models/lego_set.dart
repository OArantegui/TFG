class LegoSet {
  //Campos rebrickable
  final String setNum;
  final String name;
  final int year;
  final int themeId;
  final int numParts;
  final String imgUrl;
  //Campos de brickset
  final double? rrp;
  final String? availability;
  final String? barcode;

  LegoSet({
    required this.setNum,
    required this.name,
    required this.year,
    required this.themeId,
    required this.numParts,
    required this.imgUrl,
    this.rrp,
    this.availability,
    this.barcode,
  });

  factory LegoSet.fromJson(Map<String, dynamic> json) {
    return LegoSet(
      setNum: json['set_num'],
      name: json['name'],
      year: json['year'],
      themeId: json['theme_id'],
      numParts: json['num_parts'],
      imgUrl: json['set_img_url'] ?? 'https://via.placeholder.com/150', // Fallback si no hay imagen

      // MAPEANDO LOS NUEVOS CAMPOS
      // Usamos (as num).toDouble() porque a veces los JSON envían "800" en vez de "800.0" y Dart crashea
      rrp: json['officialRrp'] != null ? (json['officialRrp'] as num).toDouble() : null,
      availability: json['availability'],
      barcode: json['barcode'],
    );
  }
}