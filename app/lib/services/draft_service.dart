import 'dart:math';
import 'draft_store.dart';

class DraftService {
  static final Set<String> _completedPages = {};

  static void markCompleted(String pageId) => _completedPages.add(pageId);
  static bool isCompleted(String pageId) => _completedPages.contains(pageId);
  static void clearCompleted(String pageId) => _completedPages.remove(pageId);

  static Future<void> autoSave(
    String pageId,
    String pageTitle,
    Map<String, dynamic> fields,
    bool sensitiveFilled,
  ) async {
    if (_completedPages.contains(pageId)) return;
    final existing = await DraftStore.getDraft(pageId);
    final draftId = (existing?['draft_id'] as String?) ?? _newId();
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

  static String _newId() {
    final rand = Random.secure();
    return List.generate(16, (_) => rand.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }
}
