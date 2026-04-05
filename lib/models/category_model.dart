import 'package:flutter/material.dart';

class CategoryModel {
  final int? id;
  final String name;
  final int iconCode;
  final int colorValue;
  final String type; // 'income' | 'expense' | 'both'

  const CategoryModel({
    this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
    required this.type,
  });

  Color get color => Color(colorValue);
  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'icon_code': iconCode,
        'color_value': colorValue,
        'type': type,
      };

  factory CategoryModel.fromMap(Map<String, dynamic> map) => CategoryModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        iconCode: map['icon_code'] as int,
        colorValue: map['color_value'] as int,
        type: map['type'] as String,
      );

  CategoryModel copyWith({
    int? id,
    String? name,
    int? iconCode,
    int? colorValue,
    String? type,
  }) =>
      CategoryModel(
        id: id ?? this.id,
        name: name ?? this.name,
        iconCode: iconCode ?? this.iconCode,
        colorValue: colorValue ?? this.colorValue,
        type: type ?? this.type,
      );
}
