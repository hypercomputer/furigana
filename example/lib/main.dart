import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:furigana/furigana.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final data = await rootBundle.load("packages/furigana/assets/ipadic/char.bin");
  print("char.bin loaded: ${data.lengthInBytes} bytes");

  final annotator =
      FuriganaAnnotator(dictionaryDir: "packages/furigana/assets/ipadic"); // bundled asset
  await annotator.init();

  runApp(DemoApp(annotator));
}

class DemoApp extends StatelessWidget {
  const DemoApp(this.annotator, {super.key});

  final FuriganaAnnotator annotator;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Furigana Demo',
      home: Scaffold(
        appBar: AppBar(title: const Text('Furigana Demo')),
        body: FutureBuilder<List<RubySegment>>(
          future: annotator.annotate('大人になっても勉強を続けたい。'),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: RubyText(snapshot.data!),
              ),
            );
          },
        ),
      ),
    );
  }
}