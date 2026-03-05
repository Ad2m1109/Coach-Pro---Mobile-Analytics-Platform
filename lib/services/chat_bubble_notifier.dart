import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controls the visibility of the floating AI Assistant bubble.
class ChatBubbleNotifier extends ChangeNotifier {
  static const String _prefKey = 'chat_bubble_visible';

  bool _isVisible;
  bool _isChatOpen = false;

  ChatBubbleNotifier(this._isVisible);

  bool get isVisible => _isVisible;
  bool get isChatOpen => _isChatOpen;

  void toggle() {
    _isVisible = !_isVisible;
    _save();
    notifyListeners();
  }

  void show() {
    _isVisible = true;
    _save();
    notifyListeners();
  }

  void hide() {
    _isVisible = false;
    _save();
    notifyListeners();
  }

  void openChat() {
    _isChatOpen = true;
    notifyListeners();
  }

  void closeChat() {
    _isChatOpen = false;
    notifyListeners();
  }

  void _save() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(_prefKey, _isVisible);
  }

  static Future<bool> getVisibilityFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? true; // visible by default
  }
}
