class LegoTheme {
  final int id;
  final String name;
  final String fullName;
  final int? parentId;

  LegoTheme({required this.id, required this.name, required this.fullName, this.parentId});

  // Factory para crear el objeto desde el JSON de la API
  factory LegoTheme.fromJson(Map<String, dynamic> json) {
    return LegoTheme(
      id: json['id'],
      name: json['name'],
      fullName: json['fullName'] ?? json['name'],
      parentId: json['parent_id'],
    );
  }
}