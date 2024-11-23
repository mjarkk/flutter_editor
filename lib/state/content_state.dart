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

class ContentState {
  final List<String> buffer;
  CursorLocation cursor = CursorLocation(0, 0, 0);

  ContentState(String buffer) : buffer = _buffToLines(buffer);

  bool setCursor(int lineIdx, int charIdx) {
    if (lineIdx < 0) {
      lineIdx = 0;
    } else if (lineIdx >= buffer.length) {
      lineIdx = buffer.length - 1;
    }

    if (charIdx < 0) {
      charIdx = 0;
    } else if (charIdx > 0) {
      final line = buffer[lineIdx];
      if (charIdx > line.length) {
        charIdx = line.length;
      }
    }

    if (cursor.line == lineIdx && cursor.char == charIdx) {
      return false;
    }

    cursor = CursorLocation(
      lineIdx,
      charIdx,
      charIdx,
    );

    return true;
  }
}
