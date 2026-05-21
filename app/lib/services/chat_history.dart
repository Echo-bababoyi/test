/// 跨 AgentFab 开关与跨页面持久化聊天气泡记录。
/// 仅保存在内存中（页面刷新即清空），不写 localStorage。
class ChatHistory {
  ChatHistory._();
  static final instance = ChatHistory._();

  final List<Map<String, dynamic>> items = [];

  void clear() => items.clear();
}
