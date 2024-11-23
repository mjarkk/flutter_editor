import 'dart:math';

import 'package:flutter/services.dart';

import 'keyboard_handler.dart';

const specialCharacters = '`~!@#\$%^&*()-+={}[];:\'"\\|<,>.?/';

class VscodeKeyboardHandler extends BaseKeyboardHandler {
  VscodeKeyboardHandler(super.state);

  @override
  bool hanldeKeyPress(KeyEvent event) {
    final key = event.logicalKey.keyLabel;

    if (ctrlPressed) {
      if (key == "Arrow Right") {
        ctrlArrowRight();
        return true;
      } else if (key == "Arrow Left") {
        ctrlArrowLeft();
        return true;
      }

      return false;
    }

    if (key == "Backspace") {
      backspaceAtCursor();
      return true;
    } else if (key == "Delete") {
      deleteAtCursor();
      return true;
    } else if (key == "Arrow Right") {
      arrowRight();
      return true;
    } else if (key == "Arrow Left") {
      arrowLeft();
      return true;
    } else if (key == "Arrow Up") {
      arrowUp();
      return true;
    } else if (key == "Arrow Down") {
      arrowDown();
      return true;
    } else if (event.character != null) {
      placeAtCursor(event.character!);
      return true;
    }

    return false;
  }

  placeAtCursor(String text) {
    text = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('\t', '  ');

    final textLines = text.split('\n');
    final line = state.buffer[state.cursor.line];

    if (textLines.length == 1) {
      // Easy money just add the character to the current line
      state.buffer[state.cursor.line] = line.substring(0, state.cursor.char) +
          text +
          line.substring(state.cursor.char);
      state.cursor.char += text.length;
      return;
    }

    // The text placed has multiple lines, we need to do more work
    final prefix = line.substring(0, state.cursor.char);
    final suffix = line.substring(state.cursor.char);
    textLines.first = prefix + textLines.first;
    final newCursorChar = textLines.last.length;
    textLines.last = textLines.last + suffix;

    state.buffer.removeAt(state.cursor.line);
    state.buffer.insertAll(state.cursor.line, textLines);

    state.setCursor(
      state.cursor.line + textLines.length - 1,
      newCursorChar,
    );
  }

  backspaceAtCursor() {
    final line = state.buffer[state.cursor.line];
    if (state.cursor.char == 0) {
      // We need to join the current line with the previous line
      if (state.cursor.line == 0) {
        return;
      }

      final prevLine = state.buffer[state.cursor.line - 1];
      state.buffer[state.cursor.line - 1] += line;
      state.buffer.removeAt(state.cursor.line);
      state.setCursor(state.cursor.line - 1, prevLine.length);
      return;
    }

    // We can remove a character from the current line
    final before = line.substring(0, state.cursor.char - 1);
    final after = line.substring(state.cursor.char);
    state.buffer[state.cursor.line] = before + after;
    state.cursor.char -= 1;
  }

  deleteAtCursor() {
    final line = state.buffer[state.cursor.line];
    if (state.cursor.char >= line.length) {
      // We need to join the current line with the next line
      if (state.cursor.line + 1 >= state.buffer.length) {
        return;
      }

      final nextLine = state.buffer[state.cursor.line + 1];
      state.buffer[state.cursor.line] += nextLine;
      state.buffer.removeAt(state.cursor.line + 1);
      return;
    }

    // We can remove a character from the current line
    final before = line.substring(0, state.cursor.char);
    final after = line.substring(state.cursor.char + 1);
    state.buffer[state.cursor.line] = before + after;
  }

  arrowLeft() {
    if (state.cursor.char > 0) {
      state.setCursor(
        state.cursor.line,
        state.cursor.char - 1,
      );
      return;
    }

    // We need to move to the previous line
    if (state.cursor.line == 0) {
      return;
    }
    state.setCursor(
      state.cursor.line - 1,
      state.buffer[state.cursor.line - 1].length,
    );
  }

  arrowRight() {
    final line = state.buffer[state.cursor.line];
    if (line.length >= state.cursor.char + 1) {
      state.setCursor(
        state.cursor.line,
        state.cursor.char + 1,
      );
      return;
    }

    // We need to move to the next line
    if (state.cursor.line + 1 >= state.buffer.length) {
      return;
    }

    state.setCursor(
      state.cursor.line + 1,
      0,
    );
  }

  ctrlArrowRight() {
    int lineIdx = state.cursor.line;
    int charIdx = state.cursor.char;
    String line = state.buffer[lineIdx];
    if (line.length <= charIdx) {
      lineIdx += 1;
      if (lineIdx >= state.buffer.length) {
        return;
      }
      line = state.buffer[lineIdx];
      charIdx = 0;
    }

    while (charIdx < line.length && line[charIdx] == ' ') {
      charIdx++;
    }

    if (charIdx < line.length && line[charIdx] != ' ') {
      final c = line[charIdx];
      final isSpecial = specialCharacters.contains(c);
      charIdx++;

      if (isSpecial) {
        while (charIdx < line.length &&
            specialCharacters.contains(line[charIdx])) {
          charIdx++;
        }
      } else {
        while (charIdx < line.length) {
          final c = line[charIdx];
          if (!specialCharacters.contains(c) && c != ' ') {
            charIdx++;
          } else {
            break;
          }
        }
      }
    }

    state.setCursor(lineIdx, charIdx);
  }

  ctrlArrowLeft() {
    int lineIdx = state.cursor.line;
    int charIdx = state.cursor.char;
    String line = state.buffer[lineIdx];
    if (charIdx == 0) {
      lineIdx -= 1;
      if (lineIdx < 0) {
        return;
      }
      line = state.buffer[lineIdx];
      charIdx = line.length;
    }

    while (charIdx > 0 && line[charIdx - 1] == ' ') {
      charIdx--;
    }

    if (charIdx > 0 && line[charIdx - 1] != ' ') {
      final c = line[charIdx - 1];
      final isSpecial = specialCharacters.contains(c);
      charIdx--;

      if (isSpecial) {
        while (charIdx > 0 && specialCharacters.contains(line[charIdx - 1])) {
          charIdx--;
        }
      } else {
        while (charIdx > 0) {
          final c = line[charIdx - 1];
          if (!specialCharacters.contains(c) && c != ' ') {
            charIdx--;
          } else {
            break;
          }
        }
      }
    }

    state.setCursor(lineIdx, charIdx);
  }

  arrowUp() {
    if (state.cursor.line == 0) {
      return;
    }

    // Do not use setTextCursorLocation in this method
    state.cursor.line--;
    state.cursor.char = min(
      state.cursor.lastChar,
      state.buffer[state.cursor.line].length,
    );
  }

  arrowDown() {
    if (state.cursor.line + 1 >= state.buffer.length) {
      return;
    }

    // Do not use setTextCursorLocation in this method
    state.cursor.line++;
    state.cursor.char = min(
      state.cursor.lastChar,
      state.buffer[state.cursor.line].length,
    );
  }
}
