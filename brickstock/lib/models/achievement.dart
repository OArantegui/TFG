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
  
  IconData get iconData {
    switch (iconName) {
      case 'exposure_plus_1': return Icons.exposure_plus_1;
      case 'local_fire_department': return Icons.local_fire_department;
      case 'diamond': return Icons.diamond;
      // Nuevos iconos de Minifiguras
      case 'people': return Icons.people;
      case 'groups': return Icons.groups;
      case 'public': return Icons.public;
      // Nuevos iconos de Valor
      case 'savings': return Icons.savings;
      case 'trending_up': return Icons.trending_up;
      case 'account_balance': return Icons.account_balance;
      // Nuevos iconos de Temas
      case 'category': return Icons.category;
      case 'museum': return Icons.museum;
      case 'workspace_premium': return Icons.workspace_premium;
      default: return Icons.emoji_events;
    }
  }
}