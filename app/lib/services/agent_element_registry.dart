import 'package:flutter/material.dart';

class AgentElementRegistry {
  static final Map<String, Map<String, GlobalKey>> _keys = {};
  static final Map<String, Map<String, TextEditingController>> _controllers = {};
  static final Map<String, Map<String, void Function(String)>> _appliers = {};

  static GlobalKey register(String route, String elementKey) {
    final pageMap = _keys.putIfAbsent(route, () => {});
    return pageMap.putIfAbsent(elementKey, () => GlobalKey());
  }

  static GlobalKey? get(String route, String elementKey) =>
      _keys[route]?[elementKey];

  static void registerController(String route, String elementKey, TextEditingController controller) {
    final pageMap = _controllers.putIfAbsent(route, () => {});
    pageMap[elementKey] = controller;
  }

  static TextEditingController? getController(String route, String elementKey) =>
      _controllers[route]?[elementKey];

  static void registerApplier(String route, String key, void Function(String) fn) {
    _appliers.putIfAbsent(route, () => {})[key] = fn;
  }

  static void Function(String)? getApplier(String route, String key) => _appliers[route]?[key];

  static void unregister(String route, String elementKey) {
    _keys[route]?.remove(elementKey);
    _controllers[route]?.remove(elementKey);
    _appliers[route]?.remove(elementKey);
  }

  static void unregisterPage(String route) {
    _keys.remove(route);
    _controllers.remove(route);
    _appliers.remove(route);
  }
}
