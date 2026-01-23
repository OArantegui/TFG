class LegoSet {
  final String setNum;
  final String name;
  final int year;
  final int themeId;
  final int numParts;
  final String imgUrl;

  LegoSet({
    required this.setNum,
    required this.name,
    required this.year,
    required this.themeId,
    required this.numParts,
    required this.imgUrl,
  });

  factory LegoSet.fromJson(Map<String, dynamic> json) {
    return LegoSet(
      setNum: json['set_num'],
      name: json['name'],
      year: json['year'],
      themeId: json['theme_id'],
      numParts: json['num_parts'],
      imgUrl: json['set_img_url'] ?? 'https://via.placeholder.com/150', // Fallback si no hay imagen
    );
  }
}