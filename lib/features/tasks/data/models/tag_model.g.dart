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
      name: fields[0] as String,
      backgroundColor: Color(fields[1] as int), // Truyền backgroundColor từ fields[1]
      textColor: Color(fields[2] as int), // Truyền textColor từ fields[2]
      isArchived: fields[3] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, Tag obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.backgroundColorValue)
      ..writeByte(2)
      ..write(obj.textColorValue)
      ..writeByte(3)
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