import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './example.dart';

class Editor extends StatefulWidget {
  final TextStyle textStyle;

  const Editor({
    required this.textStyle,
    super.key,
  });

  @override
  State<Editor> createState() => _EditorState();
}

List<String> _buffToLines(String input) {
  final lines = input.split('\n');
  if (lines[0] == "") {
    return lines;
  }

  final firstLine = lines[0];
  if (firstLine[firstLine.length - 1] != '\r') {
    return lines;
  }

  return lines.map((line) {
    if (line == "") {
      return line;
    }
    if (line[line.length - 1] != '\r') {
      return line;
    }

    return line.substring(0, line.length - 1);
  }).toList();
}

class CursorLocation {
  int line;
  int char;
  int lastChar;

  CursorLocation(this.line, this.char, this.lastChar);
}

class _EditorState extends State<Editor> {
  List<String> buffer = _buffToLines(exampleCode);
  Size textSize = const Size(12, 26);
  Offset cursorPosition = const Offset(0, 0);
  CursorLocation textCursorLocation = CursorLocation(0, 0, 0);
  final FocusNode focusNode = FocusNode();

  @override
  void initState() {
    TextPainter textPainter = TextPainter(
      text: TextSpan(text: 'W', style: widget.textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    textSize = textPainter.size;
    super.initState();
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  setTextCursorLocation(int line, int char) {
    textCursorLocation = CursorLocation(
      line,
      char,
      char,
    );
  }

  placeAtCursor(String text) {
    text = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('\t', '  ');

    final textLines = text.split('\n');
    final line = buffer[textCursorLocation.line];

    if (textLines.length == 1) {
      // Easy money just add the character to the current line
      buffer[textCursorLocation.line] =
          line.substring(0, textCursorLocation.char) +
              text +
              line.substring(textCursorLocation.char);
      textCursorLocation.char += text.length;
      return;
    }

    // The text placed has multiple lines, we need to do more work
    final prefix = line.substring(0, textCursorLocation.char);
    final suffix = line.substring(textCursorLocation.char);
    textLines.first = prefix + textLines.first;
    final newCursorChar = textLines.last.length;
    textLines.last = textLines.last + suffix;

    buffer.removeAt(textCursorLocation.line);
    buffer.insertAll(textCursorLocation.line, textLines);

    setTextCursorLocation(
      textCursorLocation.line + textLines.length - 1,
      newCursorChar,
    );
  }

  backspaceAtCursor() {
    final line = buffer[textCursorLocation.line];
    if (textCursorLocation.char == 0) {
      // We need to join the current line with the previous line
      if (textCursorLocation.line == 0) {
        return;
      }

      final prevLine = buffer[textCursorLocation.line - 1];
      buffer[textCursorLocation.line - 1] += line;
      buffer.removeAt(textCursorLocation.line);
      setTextCursorLocation(textCursorLocation.line - 1, prevLine.length);
      return;
    }

    // We can remove a character from the current line
    final before = line.substring(0, textCursorLocation.char - 1);
    final after = line.substring(textCursorLocation.char);
    buffer[textCursorLocation.line] = before + after;
    textCursorLocation.char -= 1;
  }

  deleteAtCursor() {
    final line = buffer[textCursorLocation.line];
    if (textCursorLocation.char >= line.length) {
      // We need to join the current line with the next line
      if (textCursorLocation.line + 1 >= buffer.length) {
        return;
      }

      final nextLine = buffer[textCursorLocation.line + 1];
      buffer[textCursorLocation.line] += nextLine;
      buffer.removeAt(textCursorLocation.line + 1);
      return;
    }

    // We can remove a character from the current line
    final before = line.substring(0, textCursorLocation.char);
    final after = line.substring(textCursorLocation.char + 1);
    buffer[textCursorLocation.line] = before + after;
  }

  arrowLeft() {
    if (textCursorLocation.char > 0) {
      setTextCursorLocation(
        textCursorLocation.line,
        textCursorLocation.char - 1,
      );
      return;
    }

    // We need to move to the previous line
    if (textCursorLocation.line == 0) {
      return;
    }
    setTextCursorLocation(
      textCursorLocation.line - 1,
      buffer[textCursorLocation.line - 1].length,
    );
  }

  arrowRight() {
    final line = buffer[textCursorLocation.line];
    if (line.length >= textCursorLocation.char + 1) {
      setTextCursorLocation(
        textCursorLocation.line,
        textCursorLocation.char + 1,
      );
      return;
    }

    // We need to move to the next line
    if (textCursorLocation.line + 1 >= buffer.length) {
      return;
    }

    setTextCursorLocation(
      textCursorLocation.line + 1,
      0,
    );
  }

  arrowUp() {
    if (textCursorLocation.line == 0) {
      return;
    }

    // Do not use setTextCursorLocation in this method
    textCursorLocation.line--;
    textCursorLocation.char = min(
      textCursorLocation.lastChar,
      buffer[textCursorLocation.line].length,
    );
  }

  arrowDown() {
    if (textCursorLocation.line + 1 >= buffer.length) {
      return;
    }

    // Do not use setTextCursorLocation in this method
    textCursorLocation.line++;
    textCursorLocation.char = min(
      textCursorLocation.lastChar,
      buffer[textCursorLocation.line].length,
    );
  }

  handleKeyEvent(KeyEvent event) {
    final key = event.logicalKey.keyLabel;
    if (event is KeyUpEvent) {
      // print("Key up: $key");
    } else if (key == "Backspace") {
      setState(() => backspaceAtCursor());
    } else if (key == "Delete") {
      setState(() => deleteAtCursor());
    } else if (key == "Arrow Right") {
      setState(() => arrowRight());
    } else if (key == "Arrow Left") {
      setState(() => arrowLeft());
    } else if (key == "Arrow Up") {
      setState(() => arrowUp());
    } else if (key == "Arrow Down") {
      setState(() => arrowDown());
    } else if (event.character != null) {
      setState(() => placeAtCursor(event.character!));
    } else if (event is KeyDownEvent) {
      print("Key down: $key");
    } else if (event is KeyRepeatEvent) {
      print("Key repeat: $key");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: widget.textStyle,
      child: Focus(
        onKeyEvent: (FocusNode node, KeyEvent event) => KeyEventResult.handled,
        child: KeyboardListener(
          autofocus: true,
          focusNode: focusNode,
          onKeyEvent: handleKeyEvent,
          child: MouseRegion(
            onHover: (event) => cursorPosition = event.position,
            cursor: SystemMouseCursors.text,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  int lineIdx = cursorPosition.dy ~/ textSize.height;
                  int charIdx = (cursorPosition.dx / textSize.width).round();

                  if (lineIdx >= buffer.length) {
                    lineIdx = buffer.length - 1;
                  }

                  final line = buffer[lineIdx];

                  if (charIdx > line.length) {
                    charIdx = line.length;
                  }

                  setTextCursorLocation(lineIdx, charIdx);
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(buffer.length, (lineIdx) {
                  return _VisualLine(
                    buffer[lineIdx],
                    textSize: textSize,
                    cursorPosition: textCursorLocation.line == lineIdx
                        ? textCursorLocation.char
                        : null,
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VisualLine extends StatelessWidget {
  final String line;
  final int? cursorPosition;
  final Size textSize;

  const _VisualLine(
    this.line, {
    required this.textSize,
    this.cursorPosition,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Widget contentWidget = Row(
      children: List.generate(line.length + 1, (charIdx) {
        final char = line.length == charIdx ? null : line[charIdx];

        Widget? letterWidget = char != null ? Text(char) : null;

        return SizedBox(
          width: textSize.width,
          height: textSize.height,
          child: letterWidget,
        );
      }),
    );

    if (cursorPosition != null) {
      contentWidget = Stack(children: [
        contentWidget,
        Positioned(
          left: cursorPosition! * textSize.width,
          top: 0,
          child: Container(
            width: 2,
            height: textSize.height,
            color: Colors.red,
          ),
        ),
      ]);
    }

    return SizedBox(
      height: textSize.height,
      child: contentWidget,
    );
  }
}
