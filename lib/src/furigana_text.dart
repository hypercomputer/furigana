import 'package:flutter/widgets.dart';
import 'package:furigana_text/src/annotator.dart';
import 'package:ruby_text/ruby_text.dart';

class FuriganaText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextStyle? rubyStyle;

  const FuriganaText(this.text, {super.key, this.style, this.rubyStyle});

  @override
  State<FuriganaText> createState() => _FuriganaState();
}

class _FuriganaState extends State<FuriganaText> {
  Widget? _child;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final annotator = FuriganaAnnotator();
    await annotator.init();

    final tokens = await annotator.tokenize(widget.text);
    final data = tokens
        .map((t) => RubyTextData(t.text, ruby: t.ruby))
        .toList(growable: false);

    setState(() {
      _child = RubyText(
        data,
        style: widget.style,
        rubyStyle: widget.rubyStyle,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return _child ?? const SizedBox.shrink(); // Or a placeholder/loading indicator
  }
}