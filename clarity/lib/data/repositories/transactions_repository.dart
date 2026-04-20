import 'package:uuid/uuid.dart';
import '../local/hive_service.dart';
import '../local/entities/transaction_entity.dart';

const _uuid = Uuid();

class TransactionsRepository {
  void add(TransactionEntity tx) {
    tx.id = _uuid.v4();
    HiveService.transactions.put(tx.id, tx);
  }

  List<TransactionEntity> getToday() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return HiveService.transactions.values
        .where((tx) => tx.timestamp.isAfter(start) || tx.timestamp.isAtSameMomentAs(start))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<TransactionEntity> getLast7Days() {
    final start = DateTime.now().subtract(const Duration(days: 7));
    return HiveService.transactions.values
        .where((tx) => tx.timestamp.isAfter(start))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  List<TransactionEntity> getAll() {
    return HiveService.transactions.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  void delete(String id) {
    HiveService.transactions.delete(id);
  }

  void clearAll() {
    HiveService.transactions.clear();
  }
}
