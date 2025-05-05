import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'tag_model.g.dart';

@HiveType(typeId: 2)
class Tag {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int backgroundColorValue; // Lưu giá trị nguyên thủy của backgroundColor

  @HiveField(2)
  final int textColorValue; // Lưu giá trị nguyên thủy của textColor

  @HiveField(3)
  final bool isArchived;

  Tag({
    required this.name,
    required Color backgroundColor,
    required Color textColor,
    this.isArchived = false,
  })  : backgroundColorValue = backgroundColor.value,
        textColorValue = textColor.value;

  Color get backgroundColor => Color(backgroundColorValue);
  Color get textColor => Color(textColorValue);
}