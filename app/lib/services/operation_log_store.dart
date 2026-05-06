import 'package:idb_shim/idb_browser.dart';
import 'db_init.dart';

const _storeName = 'operation_logs';
const _maxLogs = 50;

class OperationLogStore {
  static Future<void> saveLog(Map<String, dynamic> log) async {
    final db = await DbInit.open();
    final tx = db.transaction(_storeName, idbModeReadWrite);
    final store = tx.objectStore(_storeName);

    final all = await store.getAll();
    if (all.length >= _maxLogs) {
      final oldest = all.first as Map;
      await store.delete(oldest['log_id']);
    }

    await store.put(log);
    await tx.completed;
  }

  static Future<List<Map<String, dynamic>>> getAllLogs() async {
    final db = await DbInit.open();
    final tx = db.transaction(_storeName, idbModeReadOnly);
    final store = tx.objectStore(_storeName);
    final all = await store.getAll();
    await tx.completed;
    return all.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> deleteLog(String logId) async {
    final db = await DbInit.open();
    final tx = db.transaction(_storeName, idbModeReadWrite);
    final store = tx.objectStore(_storeName);
    await store.delete(logId);
    await tx.completed;
  }
}
