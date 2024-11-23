import 'package:code_editor/state/keyboard_handler/vscode_keyboard_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'example.dart';
import 'state/content_state.dart';

class Editor extends StatefulWidget {
  final TextStyle textStyle;

  const Editor({
    required this.textStyle,
    super.key,
  });

  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  late final ContentState state;
  late final VscodeKeyboardHandler keyboardHandler;
  Size textSize = const Size(12, 26);
  Offset mousePosition = const Offset(0, 0);
  final FocusNode focusNode = FocusNode();

  _EditorState() {
    state = ContentState(exampleCode);
    keyboardHandler = VscodeKeyboardHandler(state);
  }

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

  handleKeyEvent(KeyEvent event) {
    if (keyboardHandler.handleKeyEvent(event)) {
      setState(() {});
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
            onHover: (event) => mousePosition = event.position,
            cursor: SystemMouseCursors.text,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  int lineIdx = mousePosition.dy ~/ textSize.height;
                  int charIdx = (mousePosition.dx / textSize.width).round();

                  if (lineIdx >= state.buffer.length) {
                    lineIdx = state.buffer.length - 1;
                  }

                  final line = state.buffer[lineIdx];

                  if (charIdx > line.length) {
                    charIdx = line.length;
                  }

                  state.setCursor(lineIdx, charIdx);
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(state.buffer.length, (lineIdx) {
                  return _VisualLine(
                    state.buffer[lineIdx],
                    textSize: textSize,
                    cursorPosition:
                        state.cursor.line == lineIdx ? state.cursor.char : null,
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
