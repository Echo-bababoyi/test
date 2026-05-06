import 'package:flutter/material.dart';

class AgentElementRegistry {
  static final Map<String, GlobalKey> _keys = {};
  static final Map<String, TextEditingController> _controllers = {};

  static GlobalKey register(String elementKey) {
    _keys[elementKey] ??= GlobalKey();
    return _keys[elementKey]!;
  }

  static GlobalKey? get(String elementKey) => _keys[elementKey];

  static void unregister(String elementKey) {
    _keys.remove(elementKey);
    _controllers.remove(elementKey);
  }

  static void registerController(String elementKey, TextEditingController controller) {
    _controllers[elementKey] = controller;
  }

  static TextEditingController? getController(String elementKey) => _controllers[elementKey];
}
