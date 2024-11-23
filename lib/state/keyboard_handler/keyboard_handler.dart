import 'dart:io' show Platform;

import 'package:code_editor/state/content_state.dart';
import 'package:flutter/services.dart';

class BaseKeyboardHandler {
  final ContentState state;
  bool ctrlPressed = false;
  bool altPressed = false;
  bool metaPressed = false;

  BaseKeyboardHandler(this.state);

  bool handleKeyEvent(KeyEvent event) {
    final key = event.logicalKey.keyLabel;
    if (event is KeyUpEvent) {
      if (key.startsWith("Control ")) {
        ctrlPressed = false;
      } else if (key.startsWith("Alt ")) {
        altPressed = false;
      } else if (key.startsWith("Meta ") && Platform.isMacOS) {
        metaPressed = false;
      }
      return false;
    }

    if (event is KeyDownEvent) {
      if (key.startsWith("Control ")) {
        ctrlPressed = true;
        return false;
      } else if (key.startsWith("Alt ")) {
        altPressed = true;
        return false;
      } else if (key.startsWith("Meta ") && Platform.isMacOS) {
        metaPressed = true;
        return false;
      }
    }

    return hanldeKeyPress(event);
  }

  bool hanldeKeyPress(KeyEvent event) {
    // Override me!!
    return false;
  }
}
