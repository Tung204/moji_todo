import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart'; // THÊM: Để tạo ID unique

part 'project_model.g.dart';

@HiveType(typeId: 1)
class Project {
  @HiveField(0)
  final String id; // THÊM: ID unique cho Project

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int colorValue;

  @HiveField(3)
  final bool isArchived;

  Project({
    String? id, // THÊM: Cho phép truyền ID, nếu null thì tự tạo
    required this.name,
    required Color color,
    this.isArchived = false,
  })  : id = id ?? const Uuid().v4(), // THÊM: Tạo ID nếu không được cung cấp
        colorValue = color.value;

  Color get color => Color(colorValue);
}