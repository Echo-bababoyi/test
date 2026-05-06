import 'package:flutter/material.dart';

class AgentElementRegistry {
  static final Map<String, GlobalKey> _keys = {};

  static GlobalKey register(String elementKey) {
    _keys[elementKey] ??= GlobalKey();
    return _keys[elementKey]!;
  }

  static GlobalKey? get(String elementKey) => _keys[elementKey];

  static void unregister(String elementKey) => _keys.remove(elementKey);
}
