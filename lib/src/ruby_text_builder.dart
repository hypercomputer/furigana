import 'package:flutter/widgets.dart';
import 'package:ruby_text/ruby_text.dart';
import 'annotator.dart';

/// Helper that turns a plain sentence into a `RubyText` widget.
Future<Widget> buildRubyText(
  FuriganaAnnotator annotator,
  String sentence, {
  TextStyle? style,
  TextStyle? rubyStyle,
}) async {
  final toks = await annotator.tokenize(sentence);

  final data = toks
      .map((t) => RubyTextData(t.surface, ruby: t.ruby))
      .toList(growable: false);

  return RubyText(
    data,
    style: style,
    rubyStyle: rubyStyle,
  );
}