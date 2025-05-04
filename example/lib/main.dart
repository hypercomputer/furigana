import 'package:flutter/material.dart';
import 'package:furigana_text/furigana_text.dart';

void main() {
  runApp( Demo());
}

class Demo extends StatelessWidget {
  const Demo({super.key});

  static const sentence =
      '今日、大人になった箱入り娘の美緒は、寿司や煙草を買いに七夕祭りへ行き、道端で外国産の盆栽を眺めながら、食べ物と飲み物を堪能し、働き者の友人に手作り照り焼きの作り方を教え、最後に古びた辞書で難しい読み方を調べた。';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Furigana Demo')),
        body: Padding(
          padding: EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: FuriganaText(
              sentence,
              style: TextStyle(fontSize: 26),
              rubyStyle: TextStyle(fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }
}