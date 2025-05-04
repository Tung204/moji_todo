// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      id: fields[0] as int?,
      title: fields[1] as String?,
      note: fields[2] as String?,
      dueDate: fields[3] as DateTime?,
      priority: fields[4] as String?,
      project: fields[5] as String?,
      tags: (fields[6] as List?)?.cast<String>(),
      estimatedPomodoros: fields[7] as int?,
      completedPomodoros: fields[8] as int?,
      category: fields[9] as String?,
      isPomodoroActive: fields[10] as bool?,
      remainingPomodoroSeconds: fields[11] as int?,
      isCompleted: fields[12] as bool?,
      subtasks: (fields[13] as List?)
          ?.map((dynamic e) => (e as Map).cast<String, dynamic>())
          ?.toList(),
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.note)
      ..writeByte(3)
      ..write(obj.dueDate)
      ..writeByte(4)
      ..write(obj.priority)
      ..writeByte(5)
      ..write(obj.project)
      ..writeByte(6)
      ..write(obj.tags)
      ..writeByte(7)
      ..write(obj.estimatedPomodoros)
      ..writeByte(8)
      ..write(obj.completedPomodoros)
      ..writeByte(9)
      ..write(obj.category)
      ..writeByte(10)
      ..write(obj.isPomodoroActive)
      ..writeByte(11)
      ..write(obj.remainingPomodoroSeconds)
      ..writeByte(12)
      ..write(obj.isCompleted)
      ..writeByte(13)
      ..write(obj.subtasks);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
