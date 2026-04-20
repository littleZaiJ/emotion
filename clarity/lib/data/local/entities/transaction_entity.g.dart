// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionEntityAdapter extends TypeAdapter<TransactionEntity> {
  @override
  final int typeId = 13;

  @override
  TransactionEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransactionEntity()
      ..id = fields[0] as String
      ..timestamp = fields[1] as DateTime
      ..type = fields[2] as TransactionType
      ..expenseCategory = fields[3] as ExpenseCategory?
      ..expenseSubCategory = fields[4] as ExpenseSubCategory?
      ..laborCategory = fields[5] as LaborCategory?
      ..laborSubCategory = fields[6] as LaborSubCategory?
      ..returnCategory = fields[7] as ReturnCategory?
      ..returnSubCategory = fields[16] as ReturnSubCategory?
      ..attitude = fields[8] as Attitude?
      ..medium = fields[9] as Medium?
      ..monetaryAmount = fields[10] as double
      ..laborDurationHours = fields[11] as double
      ..hourlyRateSnapshot = fields[12] as double
      ..weight = fields[13] as double
      ..note = fields[14] as String?
      ..iqs = fields[15] as double?
      ..verdictScore = fields[17] as double?
      ..diagnosisText = fields[18] as String?
      ..actionTaken = fields[19] as String?
      ..ciDelta = fields[20] as double?
      ..crushDelusion = fields[21] as double?
      ..crushPerfunctory = fields[22] as double?
      ..crushShatter = fields[23] as double?
      ..directionV2 = fields[24] as TransactionDirection?
      ..expenseCategoryV2 = fields[25] as ExpenseCategoryV2?
      ..returnCategoryV2 = fields[26] as ReturnCategoryV2?
      ..intimacyAction = fields[27] as IntimacyAction?
      ..emotionalValueAction = fields[28] as EmotionalValueAction?
      ..baseValue = fields[29] as double?
      ..leverageMultiplier = fields[30] as double?;
  }

  @override
  void write(BinaryWriter writer, TransactionEntity obj) {
    writer
      ..writeByte(31)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.expenseCategory)
      ..writeByte(4)
      ..write(obj.expenseSubCategory)
      ..writeByte(5)
      ..write(obj.laborCategory)
      ..writeByte(6)
      ..write(obj.laborSubCategory)
      ..writeByte(7)
      ..write(obj.returnCategory)
      ..writeByte(16)
      ..write(obj.returnSubCategory)
      ..writeByte(8)
      ..write(obj.attitude)
      ..writeByte(9)
      ..write(obj.medium)
      ..writeByte(10)
      ..write(obj.monetaryAmount)
      ..writeByte(11)
      ..write(obj.laborDurationHours)
      ..writeByte(12)
      ..write(obj.hourlyRateSnapshot)
      ..writeByte(13)
      ..write(obj.weight)
      ..writeByte(14)
      ..write(obj.note)
      ..writeByte(15)
      ..write(obj.iqs)
      ..writeByte(17)
      ..write(obj.verdictScore)
      ..writeByte(18)
      ..write(obj.diagnosisText)
      ..writeByte(19)
      ..write(obj.actionTaken)
      ..writeByte(20)
      ..write(obj.ciDelta)
      ..writeByte(21)
      ..write(obj.crushDelusion)
      ..writeByte(22)
      ..write(obj.crushPerfunctory)
      ..writeByte(23)
      ..write(obj.crushShatter)
      ..writeByte(24)
      ..write(obj.directionV2)
      ..writeByte(25)
      ..write(obj.expenseCategoryV2)
      ..writeByte(26)
      ..write(obj.returnCategoryV2)
      ..writeByte(27)
      ..write(obj.intimacyAction)
      ..writeByte(28)
      ..write(obj.emotionalValueAction)
      ..writeByte(29)
      ..write(obj.baseValue)
      ..writeByte(30)
      ..write(obj.leverageMultiplier);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExpenseCategoryAdapter extends TypeAdapter<ExpenseCategory> {
  @override
  final int typeId = 0;

  @override
  ExpenseCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ExpenseCategory.gift;
      case 1:
        return ExpenseCategory.date;
      case 2:
        return ExpenseCategory.transfer;
      case 3:
        return ExpenseCategory.other;
      default:
        return ExpenseCategory.gift;
    }
  }

  @override
  void write(BinaryWriter writer, ExpenseCategory obj) {
    switch (obj) {
      case ExpenseCategory.gift:
        writer.writeByte(0);
        break;
      case ExpenseCategory.date:
        writer.writeByte(1);
        break;
      case ExpenseCategory.transfer:
        writer.writeByte(2);
        break;
      case ExpenseCategory.other:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExpenseSubCategoryAdapter extends TypeAdapter<ExpenseSubCategory> {
  @override
  final int typeId = 1;

  @override
  ExpenseSubCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ExpenseSubCategory.jewelryBags;
      case 1:
        return ExpenseSubCategory.digitalGear;
      case 2:
        return ExpenseSubCategory.flowersHandmade;
      case 3:
        return ExpenseSubCategory.fineDining;
      case 4:
        return ExpenseSubCategory.movieShow;
      case 5:
        return ExpenseSubCategory.escapeBoard;
      case 6:
        return ExpenseSubCategory.clearCart;
      case 7:
        return ExpenseSubCategory.holidayRedPacket;
      case 8:
        return ExpenseSubCategory.payBills;
      case 9:
        return ExpenseSubCategory.other;
      default:
        return ExpenseSubCategory.jewelryBags;
    }
  }

  @override
  void write(BinaryWriter writer, ExpenseSubCategory obj) {
    switch (obj) {
      case ExpenseSubCategory.jewelryBags:
        writer.writeByte(0);
        break;
      case ExpenseSubCategory.digitalGear:
        writer.writeByte(1);
        break;
      case ExpenseSubCategory.flowersHandmade:
        writer.writeByte(2);
        break;
      case ExpenseSubCategory.fineDining:
        writer.writeByte(3);
        break;
      case ExpenseSubCategory.movieShow:
        writer.writeByte(4);
        break;
      case ExpenseSubCategory.escapeBoard:
        writer.writeByte(5);
        break;
      case ExpenseSubCategory.clearCart:
        writer.writeByte(6);
        break;
      case ExpenseSubCategory.holidayRedPacket:
        writer.writeByte(7);
        break;
      case ExpenseSubCategory.payBills:
        writer.writeByte(8);
        break;
      case ExpenseSubCategory.other:
        writer.writeByte(9);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseSubCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LaborCategoryAdapter extends TypeAdapter<LaborCategory> {
  @override
  final int typeId = 2;

  @override
  LaborCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LaborCategory.emotional;
      case 1:
        return LaborCategory.physical;
      case 2:
        return LaborCategory.timeSunk;
      case 3:
        return LaborCategory.other;
      default:
        return LaborCategory.emotional;
    }
  }

  @override
  void write(BinaryWriter writer, LaborCategory obj) {
    switch (obj) {
      case LaborCategory.emotional:
        writer.writeByte(0);
        break;
      case LaborCategory.physical:
        writer.writeByte(1);
        break;
      case LaborCategory.timeSunk:
        writer.writeByte(2);
        break;
      case LaborCategory.other:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LaborCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LaborSubCategoryAdapter extends TypeAdapter<LaborSubCategory> {
  @override
  final int typeId = 6;

  @override
  LaborSubCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LaborSubCategory.lateNightComfort;
      case 1:
        return LaborSubCategory.breakIce;
      case 2:
        return LaborSubCategory.prepareSurprise;
      case 3:
        return LaborSubCategory.errandsPickup;
      case 4:
        return LaborSubCategory.movingCleaning;
      case 5:
        return LaborSubCategory.queueBuying;
      case 6:
        return LaborSubCategory.longWaiting;
      case 7:
        return LaborSubCategory.boringActivity;
      case 8:
        return LaborSubCategory.other;
      default:
        return LaborSubCategory.lateNightComfort;
    }
  }

  @override
  void write(BinaryWriter writer, LaborSubCategory obj) {
    switch (obj) {
      case LaborSubCategory.lateNightComfort:
        writer.writeByte(0);
        break;
      case LaborSubCategory.breakIce:
        writer.writeByte(1);
        break;
      case LaborSubCategory.prepareSurprise:
        writer.writeByte(2);
        break;
      case LaborSubCategory.errandsPickup:
        writer.writeByte(3);
        break;
      case LaborSubCategory.movingCleaning:
        writer.writeByte(4);
        break;
      case LaborSubCategory.queueBuying:
        writer.writeByte(5);
        break;
      case LaborSubCategory.longWaiting:
        writer.writeByte(6);
        break;
      case LaborSubCategory.boringActivity:
        writer.writeByte(7);
        break;
      case LaborSubCategory.other:
        writer.writeByte(8);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LaborSubCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReturnCategoryAdapter extends TypeAdapter<ReturnCategory> {
  @override
  final int typeId = 7;

  @override
  ReturnCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ReturnCategory.material;
      case 1:
        return ReturnCategory.emotional;
      case 2:
        return ReturnCategory.action;
      case 3:
        return ReturnCategory.other;
      default:
        return ReturnCategory.material;
    }
  }

  @override
  void write(BinaryWriter writer, ReturnCategory obj) {
    switch (obj) {
      case ReturnCategory.material:
        writer.writeByte(0);
        break;
      case ReturnCategory.emotional:
        writer.writeByte(1);
        break;
      case ReturnCategory.action:
        writer.writeByte(2);
        break;
      case ReturnCategory.other:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReturnCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReturnSubCategoryAdapter extends TypeAdapter<ReturnSubCategory> {
  @override
  final int typeId = 14;

  @override
  ReturnSubCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ReturnSubCategory.receivedGift;
      case 1:
        return ReturnSubCategory.treatMeal;
      case 2:
        return ReturnSubCategory.moneyTransfer;
      case 3:
        return ReturnSubCategory.deepTalk;
      case 4:
        return ReturnSubCategory.emotionalSupport;
      case 5:
        return ReturnSubCategory.surprise;
      case 6:
        return ReturnSubCategory.shareTask;
      case 7:
        return ReturnSubCategory.dedicatedTime;
      case 8:
        return ReturnSubCategory.other;
      default:
        return ReturnSubCategory.receivedGift;
    }
  }

  @override
  void write(BinaryWriter writer, ReturnSubCategory obj) {
    switch (obj) {
      case ReturnSubCategory.receivedGift:
        writer.writeByte(0);
        break;
      case ReturnSubCategory.treatMeal:
        writer.writeByte(1);
        break;
      case ReturnSubCategory.moneyTransfer:
        writer.writeByte(2);
        break;
      case ReturnSubCategory.deepTalk:
        writer.writeByte(3);
        break;
      case ReturnSubCategory.emotionalSupport:
        writer.writeByte(4);
        break;
      case ReturnSubCategory.surprise:
        writer.writeByte(5);
        break;
      case ReturnSubCategory.shareTask:
        writer.writeByte(6);
        break;
      case ReturnSubCategory.dedicatedTime:
        writer.writeByte(7);
        break;
      case ReturnSubCategory.other:
        writer.writeByte(8);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReturnSubCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransactionTypeAdapter extends TypeAdapter<TransactionType> {
  @override
  final int typeId = 3;

  @override
  TransactionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TransactionType.expense;
      case 1:
        return TransactionType.labor;
      case 2:
        return TransactionType.return_;
      case 3:
        return TransactionType.aiVerdict;
      case 4:
        return TransactionType.timeFriction;
      default:
        return TransactionType.expense;
    }
  }

  @override
  void write(BinaryWriter writer, TransactionType obj) {
    switch (obj) {
      case TransactionType.expense:
        writer.writeByte(0);
        break;
      case TransactionType.labor:
        writer.writeByte(1);
        break;
      case TransactionType.return_:
        writer.writeByte(2);
        break;
      case TransactionType.aiVerdict:
        writer.writeByte(3);
        break;
      case TransactionType.timeFriction:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransactionDirectionAdapter extends TypeAdapter<TransactionDirection> {
  @override
  final int typeId = 15;

  @override
  TransactionDirection read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TransactionDirection.expense;
      case 1:
        return TransactionDirection.return_;
      default:
        return TransactionDirection.expense;
    }
  }

  @override
  void write(BinaryWriter writer, TransactionDirection obj) {
    switch (obj) {
      case TransactionDirection.expense:
        writer.writeByte(0);
        break;
      case TransactionDirection.return_:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionDirectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExpenseCategoryV2Adapter extends TypeAdapter<ExpenseCategoryV2> {
  @override
  final int typeId = 16;

  @override
  ExpenseCategoryV2 read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ExpenseCategoryV2.financial;
      case 1:
        return ExpenseCategoryV2.effort;
      case 2:
        return ExpenseCategoryV2.timeFriction;
      case 3:
        return ExpenseCategoryV2.emotionalDrain;
      case 4:
        return ExpenseCategoryV2.other;
      default:
        return ExpenseCategoryV2.financial;
    }
  }

  @override
  void write(BinaryWriter writer, ExpenseCategoryV2 obj) {
    switch (obj) {
      case ExpenseCategoryV2.financial:
        writer.writeByte(0);
        break;
      case ExpenseCategoryV2.effort:
        writer.writeByte(1);
        break;
      case ExpenseCategoryV2.timeFriction:
        writer.writeByte(2);
        break;
      case ExpenseCategoryV2.emotionalDrain:
        writer.writeByte(3);
        break;
      case ExpenseCategoryV2.other:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseCategoryV2Adapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReturnCategoryV2Adapter extends TypeAdapter<ReturnCategoryV2> {
  @override
  final int typeId = 17;

  @override
  ReturnCategoryV2 read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ReturnCategoryV2.material;
      case 1:
        return ReturnCategoryV2.intimacy;
      case 2:
        return ReturnCategoryV2.emotionalValue;
      case 3:
        return ReturnCategoryV2.other;
      default:
        return ReturnCategoryV2.material;
    }
  }

  @override
  void write(BinaryWriter writer, ReturnCategoryV2 obj) {
    switch (obj) {
      case ReturnCategoryV2.material:
        writer.writeByte(0);
        break;
      case ReturnCategoryV2.intimacy:
        writer.writeByte(1);
        break;
      case ReturnCategoryV2.emotionalValue:
        writer.writeByte(2);
        break;
      case ReturnCategoryV2.other:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReturnCategoryV2Adapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class IntimacyActionAdapter extends TypeAdapter<IntimacyAction> {
  @override
  final int typeId = 18;

  @override
  IntimacyAction read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return IntimacyAction.handHold;
      case 1:
        return IntimacyAction.hug;
      case 2:
        return IntimacyAction.kiss;
      default:
        return IntimacyAction.handHold;
    }
  }

  @override
  void write(BinaryWriter writer, IntimacyAction obj) {
    switch (obj) {
      case IntimacyAction.handHold:
        writer.writeByte(0);
        break;
      case IntimacyAction.hug:
        writer.writeByte(1);
        break;
      case IntimacyAction.kiss:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IntimacyActionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EmotionalValueActionAdapter extends TypeAdapter<EmotionalValueAction> {
  @override
  final int typeId = 19;

  @override
  EmotionalValueAction read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return EmotionalValueAction.sweetTalk;
      case 1:
        return EmotionalValueAction.activeCare;
      case 2:
        return EmotionalValueAction.apology;
      default:
        return EmotionalValueAction.sweetTalk;
    }
  }

  @override
  void write(BinaryWriter writer, EmotionalValueAction obj) {
    switch (obj) {
      case EmotionalValueAction.sweetTalk:
        writer.writeByte(0);
        break;
      case EmotionalValueAction.activeCare:
        writer.writeByte(1);
        break;
      case EmotionalValueAction.apology:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmotionalValueActionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AttitudeAdapter extends TypeAdapter<Attitude> {
  @override
  final int typeId = 8;

  @override
  Attitude read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Attitude.cold;
      case 1:
        return Attitude.dismissive;
      case 2:
        return Attitude.normal;
      case 3:
        return Attitude.proactive;
      default:
        return Attitude.cold;
    }
  }

  @override
  void write(BinaryWriter writer, Attitude obj) {
    switch (obj) {
      case Attitude.cold:
        writer.writeByte(0);
        break;
      case Attitude.dismissive:
        writer.writeByte(1);
        break;
      case Attitude.normal:
        writer.writeByte(2);
        break;
      case Attitude.proactive:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttitudeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MediumAdapter extends TypeAdapter<Medium> {
  @override
  final int typeId = 9;

  @override
  Medium read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Medium.text;
      case 1:
        return Medium.voice;
      case 2:
        return Medium.media;
      default:
        return Medium.text;
    }
  }

  @override
  void write(BinaryWriter writer, Medium obj) {
    switch (obj) {
      case Medium.text:
        writer.writeByte(0);
        break;
      case Medium.voice:
        writer.writeByte(1);
        break;
      case Medium.media:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediumAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
