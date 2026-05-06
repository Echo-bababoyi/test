class SessionState {
  String? sessionId;
  String state = 'idle';
  List<Map<String, dynamic>> dialogHistory = [];
  Set<String> grantedPermissions = {};
  bool websocketConnected = false;

  void addDialog(String role, String text) {
    dialogHistory.add({'role': role, 'text': text});
    if (dialogHistory.length > 10) {
      dialogHistory.removeAt(0);
    }
  }

  void grantPermission(String permissionType) {
    grantedPermissions.add(permissionType);
  }

  void reset() {
    sessionId = null;
    state = 'idle';
    dialogHistory.clear();
    grantedPermissions.clear();
    websocketConnected = false;
  }
}
