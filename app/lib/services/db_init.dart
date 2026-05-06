import 'package:idb_shim/idb_browser.dart';

const _dbName = 'xiaozhe_draft';

class DbInit {
  static Database? _db;

  static Future<Database> open() async {
    _db ??= await idbFactoryBrowser.open(_dbName, version: 1, onUpgradeNeeded: (e) {
      final db = e.database;
      if (!db.objectStoreNames.contains('drafts')) {
        db.createObjectStore('drafts', keyPath: 'draft_id');
      }
      if (!db.objectStoreNames.contains('operation_logs')) {
        db.createObjectStore('operation_logs', keyPath: 'log_id');
      }
    });
    return _db!;
  }
}
