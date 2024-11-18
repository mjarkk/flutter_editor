const String exampleCode = """import 'package:flutter/material.dart';

class Editor extends StatefulWidget {
  const Editor({super.key});

  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  String buffer = "example code here";

  @override
  Widget build(BuildContext context) {
    return Container(child: Text(buffer));
  }
}
""";
