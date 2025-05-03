import 'package:mecab_dart/mecab_dart.dart';

class RubyToken {
  final String surface;
  final String? ruby;
  const RubyToken(this.surface, this.ruby);
}

class FuriganaAnnotator {
  FuriganaAnnotator({String? dictionaryDir})
      : _dic = dictionaryDir ?? 'packages/furigana/assets/ipadic';

  final String _dic;
  late final Mecab _mecab;
  bool _ready = false;

  Future<void> init() async {
    _mecab = Mecab();
    await _mecab.init(_dic, true);
    _ready = true;
  }

  /// Take sentence → list of tokens with optional ruby (hiragana).
  Future<List<RubyToken>> tokenize(String text) async {
    if (!_ready) throw StateError('Call init() first');
    final tokens = _mecab.parse(text);
    final out = <RubyToken>[];

    for (final t in tokens) {
      if (t.surface == 'EOS') continue;
      final surface = t.surface;
      final reading = t.features.length > 7 ? t.features[7] : '*';
      final hira = _katakanaToHiragana(reading);

      if (_hasKanji(surface) && hira != '*' && hira != surface) {
        out.add(RubyToken(surface, hira));
      } else {
        out.add(RubyToken(surface, null));
      }
    }
    return out;
  }

  /* helpers */

  bool _hasKanji(String s) =>
      s.runes.any((r) => r >= 0x4E00 && r <= 0x9FFF);

  String _katakanaToHiragana(String kata) => kata.replaceAllMapped(
        RegExp('[ァ-ヶ]'),
        (m) => String.fromCharCode(m[0]!.codeUnitAt(0) - 0x60),
      );
}