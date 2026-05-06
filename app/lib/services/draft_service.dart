import 'dart:math';
import 'draft_store.dart';

class DraftService {
  static Future<void> autoSave(
    String pageId,
    String pageTitle,
    Map<String, dynamic> fields,
    bool sensitiveFilled,
  ) async {
    final draftId = _newId();
    await DraftStore.saveDraft({
      'draft_id': draftId,
      'page_id': pageId,
      'page_title': pageTitle,
      'fields': fields,
      'sensitive_filled': sensitiveFilled,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  static Future<Map<String, dynamic>?> checkDraft(String pageId) {
    return DraftStore.getDraft(pageId);
  }

  static Future<void> restoreDraft(String draftId) async {
    // 具体字段恢复由调用方页面根据 draft['fields'] 自行处理
  }

  static String _newId() {
    final rand = Random.secure();
    return List.generate(16, (_) => rand.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }
}
