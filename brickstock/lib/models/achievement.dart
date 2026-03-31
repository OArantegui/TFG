import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final bool isUnlocked;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.isUnlocked,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      iconName: json['icon'] ?? 'star',
      isUnlocked: json['isUnlocked'] ?? false,
    );
  }

  // TFG: Mapeo manual (Factory Method pattern) para convertir Strings de BD a Iconos Material
  IconData get iconData {
    switch (iconName) {
      case 'exposure_plus_1':
        return Icons.exposure_plus_1;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'diamond':
        return Icons.diamond;
      default:
        return Icons.emoji_events;
    }
  }
}