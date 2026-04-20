// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserSettingsEntityAdapter extends TypeAdapter<UserSettingsEntity> {
  @override
  final int typeId = 5;

  @override
  UserSettingsEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSettingsEntity()
      ..hourlyRate = fields[0] as double
      ..dignityThresholdMin = fields[1] as int
      ..claudeApiKey = fields[2] as String
      ..equivalentPreferences = (fields[3] as List).cast<String>()
      ..ciValue = fields[4] as double
      ..lastRecordDate = fields[5] as DateTime?
      ..ciDeclineDays = fields[6] as int
      ..ciRiseDays = fields[7] as int
      ..hasCompletedOnboarding = fields[8] as bool
      ..autoMarkAfterMin = fields[9] as int
      ..debugMode = fields[10] as bool;
  }

  @override
  void write(BinaryWriter writer, UserSettingsEntity obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.hourlyRate)
      ..writeByte(1)
      ..write(obj.dignityThresholdMin)
      ..writeByte(2)
      ..write(obj.claudeApiKey)
      ..writeByte(3)
      ..write(obj.equivalentPreferences)
      ..writeByte(4)
      ..write(obj.ciValue)
      ..writeByte(5)
      ..write(obj.lastRecordDate)
      ..writeByte(6)
      ..write(obj.ciDeclineDays)
      ..writeByte(7)
      ..write(obj.ciRiseDays)
      ..writeByte(8)
      ..write(obj.hasCompletedOnboarding)
      ..writeByte(9)
      ..write(obj.autoMarkAfterMin)
      ..writeByte(10)
      ..write(obj.debugMode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EquivalentPreferenceAdapter extends TypeAdapter<EquivalentPreference> {
  @override
  final int typeId = 11;

  @override
  EquivalentPreference read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return EquivalentPreference.digital;
      case 1:
        return EquivalentPreference.beauty;
      case 2:
        return EquivalentPreference.gaming;
      case 3:
        return EquivalentPreference.food;
      case 4:
        return EquivalentPreference.travel;
      case 5:
        return EquivalentPreference.fashion;
      default:
        return EquivalentPreference.digital;
    }
  }

  @override
  void write(BinaryWriter writer, EquivalentPreference obj) {
    switch (obj) {
      case EquivalentPreference.digital:
        writer.writeByte(0);
        break;
      case EquivalentPreference.beauty:
        writer.writeByte(1);
        break;
      case EquivalentPreference.gaming:
        writer.writeByte(2);
        break;
      case EquivalentPreference.food:
        writer.writeByte(3);
        break;
      case EquivalentPreference.travel:
        writer.writeByte(4);
        break;
      case EquivalentPreference.fashion:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EquivalentPreferenceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
