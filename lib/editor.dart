import 'package:flutter/material.dart';
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

class _EditorState extends State<Editor> {
  List<String> buffer = _buffToLines(exampleCode);
  Size textSize = const Size(12, 26);
  Offset cursorPosition = const Offset(0, 0);

  @override
  void initState() {
    TextPainter textPainter = TextPainter(
        text: TextSpan(text: 'W', style: widget.textStyle),
        textDirection: TextDirection.ltr)
      ..layout();

    textSize = textPainter.size;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: widget.textStyle,
      child: MouseRegion(
        onHover: (event) {
          cursorPosition = event.position;
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            print('line');
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(buffer.length, (lineIdx) {
              final line = buffer[lineIdx];
              return SizedBox(
                height: textSize.height,
                child: Row(
                  children: List.generate(line.length + 1, (charIdx) {
                    final char = line.length == charIdx ? null : line[charIdx];
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        print('character: $char');
                      },
                      child: SizedBox(
                        width: textSize.width,
                        height: textSize.height,
                        child: char != null ? Text(char) : null,
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
