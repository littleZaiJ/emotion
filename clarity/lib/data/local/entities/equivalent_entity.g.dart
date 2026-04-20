// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'equivalent_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EquivalentEntityAdapter extends TypeAdapter<EquivalentEntity> {
  @override
  final int typeId = 12;

  @override
  EquivalentEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EquivalentEntity(
      id: fields[0] as String,
      name: fields[1] as String,
      unit: fields[2] as String,
      price: fields[3] as double,
      tags: (fields[4] as List).cast<String>(),
      feelingDesc: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, EquivalentEntity obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.unit)
      ..writeByte(3)
      ..write(obj.price)
      ..writeByte(4)
      ..write(obj.tags)
      ..writeByte(5)
      ..write(obj.feelingDesc);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EquivalentEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
