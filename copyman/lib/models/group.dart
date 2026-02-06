import 'package:flutter/material.dart';

class Group {
  final int id;
  final String name;
  final String color; // Hex color code (e.g., '#4CAF50')
  final int createdAt;
  final int updatedAt;

  Group({
    required this.id,
    required this.name,
    this.color = '#4CAF50',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'] as int,
      name: map['name'] as String,
      color: map['color'] as String? ?? '#4CAF50',
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  /// Convert hex color string to Flutter Color
  Color toFlutterColor() {
    final hex = color.replaceFirst('#', '0xff');
    return Color(int.parse(hex));
  }

  /// Copy with overrides
  Group copyWith({
    int? id,
    String? name,
    String? color,
    int? createdAt,
    int? updatedAt,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
