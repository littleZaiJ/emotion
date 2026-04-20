// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interaction_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InteractionEntityAdapter extends TypeAdapter<InteractionEntity> {
  @override
  final int typeId = 4;

  @override
  InteractionEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InteractionEntity()
      ..id = fields[0] as String
      ..startTime = fields[1] as DateTime
      ..endTime = fields[2] as DateTime?
      ..isCompleted = fields[3] as bool
      ..attitude = fields[4] as Attitude?
      ..medium = fields[5] as Medium?
      ..calculatedIQS = fields[6] as double?
      ..calculatedTI = fields[7] as double?
      ..isAutoTriggered = fields[8] as bool
      ..status = fields[9] as WaitStatus
      ..hourlyRateSnapshot = fields[10] as double;
  }

  @override
  void write(BinaryWriter writer, InteractionEntity obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.startTime)
      ..writeByte(2)
      ..write(obj.endTime)
      ..writeByte(3)
      ..write(obj.isCompleted)
      ..writeByte(4)
      ..write(obj.attitude)
      ..writeByte(5)
      ..write(obj.medium)
      ..writeByte(6)
      ..write(obj.calculatedIQS)
      ..writeByte(7)
      ..write(obj.calculatedTI)
      ..writeByte(8)
      ..write(obj.isAutoTriggered)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.hourlyRateSnapshot);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InteractionEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WaitStatusAdapter extends TypeAdapter<WaitStatus> {
  @override
  final int typeId = 10;

  @override
  WaitStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return WaitStatus.idle;
      case 1:
        return WaitStatus.running;
      case 2:
        return WaitStatus.evaluating;
      case 3:
        return WaitStatus.finished;
      default:
        return WaitStatus.idle;
    }
  }

  @override
  void write(BinaryWriter writer, WaitStatus obj) {
    switch (obj) {
      case WaitStatus.idle:
        writer.writeByte(0);
        break;
      case WaitStatus.running:
        writer.writeByte(1);
        break;
      case WaitStatus.evaluating:
        writer.writeByte(2);
        break;
      case WaitStatus.finished:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WaitStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
