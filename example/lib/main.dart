import 'package:flutter/material.dart';
import 'package:furigana/furigana.dart';
import 'package:furigana/src/ruby_text_builder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final annotator = FuriganaAnnotator(); // auto path
  await annotator.init();

  runApp(Demo(annotator));
}

class Demo extends StatelessWidget {
  const Demo(this.annotator, {super.key});
  final FuriganaAnnotator annotator;

  @override
  Widget build(BuildContext context) {
    const sentence = '大人になっても勉強を続けたい。';

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Furigana Demo')),
        body: Center(
          child: FutureBuilder<Widget>(
            future: buildRubyText(annotator, sentence,
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