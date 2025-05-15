// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TagAdapter extends TypeAdapter<Tag> {
  @override
  final int typeId = 2;

  @override
  Tag read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Tag(
      id: fields[0] as String,
      name: fields[1] as String,
      backgroundColor: Color(fields[2] as int), // SỬA: Đảm bảo truyền backgroundColor
      textColor: Color(fields[3] as int), // SỬA: Đảm bảo truyền textColor
      isArchived: fields[4] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, Tag obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.backgroundColorValue)
      ..writeByte(3)
      ..write(obj.textColorValue)
      ..writeByte(4)
      ..write(obj.isArchived);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is TagAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}