import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart'; // THÊM: Để tạo ID unique

part 'tag_model.g.dart';

@HiveType(typeId: 2)
class Tag {
  @HiveField(0)
  final String id; // THÊM: ID unique cho Tag

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int backgroundColorValue;

  @HiveField(3)
  final int textColorValue;

  @HiveField(4)
  final bool isArchived;

  Tag({
    String? id, // THÊM: Cho phép truyền ID, nếu null thì tự tạo
    required this.name,
    required Color backgroundColor,
    required Color textColor,
    this.isArchived = false,
  })  : id = id ?? const Uuid().v4(), // THÊM: Tạo ID nếu không được cung cấp
        backgroundColorValue = backgroundColor.value,
        textColorValue = textColor.value;

  Color get backgroundColor => Color(backgroundColorValue);
  Color get textColor => Color(textColorValue);
}