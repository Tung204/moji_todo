import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'project_model.g.dart';

@HiveType(typeId: 1)
class Project {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int colorValue; // Lưu giá trị nguyên thủy của Color (color.value)

  @HiveField(2)
  final bool isArchived;

  Project({
    required this.name,
    required Color color,
    this.isArchived = false,
  }) : colorValue = color.value;

  Color get color => Color(colorValue);
}