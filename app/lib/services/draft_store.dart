import 'package:idb_shim/idb_browser.dart';
import 'db_init.dart';

const _storeName = 'drafts';
const _maxDrafts = 10;

class DraftStore {
  static Future<void> saveDraft(Map<String, dynamic> draft) async {
    final db = await DbInit.open();
    final tx = db.transaction(_storeName, idbModeReadWrite);
    final store = tx.objectStore(_storeName);

    final all = (await store.getAll()).cast<Map<String, dynamic>>();
    for (final item in all) {
      if (item['page_id'] == draft['page_id'] && item['draft_id'] != draft['draft_id']) {
        await store.delete(item['draft_id']);
      }
    }
    final remaining = all.where((m) =>
      !(m['page_id'] == draft['page_id'] && m['draft_id'] != draft['draft_id'])
    ).toList();
    if (remaining.length >= _maxDrafts) {
      await store.delete(remaining.first['draft_id']);
    }

    await store.put(draft);
    await tx.completed;
  }

  static Future<Map<String, dynamic>?> getDraft(String pageId) async {
    final db = await DbInit.open();
    final tx = db.transaction(_storeName, idbModeReadOnly);
    final store = tx.objectStore(_storeName);
    final all = await store.getAll();
    await tx.completed;
    for (final item in all) {
      final map = Map<String, dynamic>.from(item as Map);
      if (map['page_id'] == pageId) return map;
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> getAllDrafts() async {
    final db = await DbInit.open();
    final tx = db.transaction(_storeName, idbModeReadOnly);
    final store = tx.objectStore(_storeName);
    final all = await store.getAll();
    await tx.completed;
    return all.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> deleteDraft(String draftId) async {
    final db = await DbInit.open();
    final tx = db.transaction(_storeName, idbModeReadWrite);
    final store = tx.objectStore(_storeName);
    await store.delete(draftId);
    await tx.completed;
  }
}
