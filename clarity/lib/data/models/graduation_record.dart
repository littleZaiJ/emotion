class GraduationRecord {
  final String? id;
  final String deviceId;
  final String userAlias;
  final String userTitle;
  final String exitType;
  final double totalInvestment;
  final double finalCi;
  final String aiSummary;
  final int hugCount;
  final int cheersCount;
  final int warningCount;
  final DateTime? createdAt;

  const GraduationRecord({
    this.id,
    required this.deviceId,
    required this.userAlias,
    required this.userTitle,
    required this.exitType,
    required this.totalInvestment,
    required this.finalCi,
    required this.aiSummary,
    this.hugCount = 0,
    this.cheersCount = 0,
    this.warningCount = 0,
    this.createdAt,
  });

  factory GraduationRecord.fromJson(Map<String, dynamic> json) {
    String readString(String camel, String snake) {
      final v = json[camel] ?? json[snake];
      return (v is String) ? v : (v?.toString() ?? '');
    }

    double readDouble(String camel, String snake) {
      final v = json[camel] ?? json[snake];
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    int readInt(String camel, String snake) {
      final v = json[camel] ?? json[snake];
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    DateTime? readDateTime(String camel, String snake) {
      final v = json[camel] ?? json[snake];
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return GraduationRecord(
      id: (json['id'] as String?) ?? (json['id']?.toString()),
      deviceId: readString('deviceId', 'device_id'),
      userAlias: readString('userAlias', 'user_alias'),
      userTitle: readString('userTitle', 'user_title'),
      exitType: readString('exitType', 'exit_type'),
      totalInvestment: readDouble('totalInvestment', 'total_investment'),
      finalCi: readDouble('finalCi', 'final_ci'),
      aiSummary: readString('aiSummary', 'ai_summary'),
      hugCount: readInt('hugCount', 'hug_count'),
      cheersCount: readInt('cheersCount', 'cheers_count'),
      warningCount: readInt('warningCount', 'warning_count'),
      createdAt: readDateTime('createdAt', 'created_at'),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'device_id': deviceId,
      'user_alias': userAlias,
      'user_title': userTitle,
      'exit_type': exitType,
      'total_investment': totalInvestment,
      'final_ci': finalCi,
      'ai_summary': aiSummary,
      'hug_count': hugCount,
      'cheers_count': cheersCount,
      'warning_count': warningCount,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
