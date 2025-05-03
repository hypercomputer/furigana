import 'package:flutter/widgets.dart';
import 'package:ruby_text/ruby_text.dart';
import 'annotator.dart';

/// Build a ready‑to‑display RubyText widget from a sentence.
Future<Widget> buildRubyText(
  FuriganaAnnotator annotator,
  String sentence, {
  TextStyle? style,
  TextStyle? rubyStyle,
}) async {
  final tokens = await annotator.tokenize(sentence);

  final data = tokens
      .map((t) => RubyTextData(t.text, ruby: t.ruby))   // ← use .text
      .toList(growable: false);

  return RubyText(
    data,
    style: style,
    rubyStyle: rubyStyle,
  );
}