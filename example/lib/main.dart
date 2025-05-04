import 'package:flutter/material.dart';
import 'package:furigana/furigana.dart';
import 'package:furigana/src/ruby_text_builder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(Demo());
}

class Demo extends StatelessWidget {
  const Demo({super.key});

  @override
  Widget build(BuildContext context) {
    const sentence = '今日、大人になった箱入り娘の美緒は、寿司や煙草を買いに七夕祭りへ行き、道端で外国産の盆栽を眺めながら、食べ物と飲み物を堪能し、働き者の友人に手作り照り焼きの作り方を教え、最後に古びた辞書で難しい読み方を調べた。';

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Furigana Demo')),
        body: Center(
          child: FutureBuilder<Widget>(
            future: buildRubyText(sentence,
                style: const TextStyle(fontSize: 26),
                rubyStyle: const TextStyle(fontSize: 12)),
            builder: (c, snap) =>
                snap.hasData ? snap.data! : const CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}