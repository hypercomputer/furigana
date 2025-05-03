import 'package:mecab_dart/mecab_dart.dart';

class RubyToken {
  final String surface;
  final String? ruby; // null → no furigana
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

  /* ───────────────────────── public ───────────────────────── */

  Future<List<RubyToken>> tokenize(String text) async {
    if (!_ready) throw StateError('Call init() first');
    final mecabToks = _mecab.parse(text);
    final out = <RubyToken>[];

    for (final t in mecabToks) {
      if (t.surface == 'EOS') continue;

      final surface = t.surface;
      final katakana = t.features.length > 7 ? t.features[7] : '*';
      final reading = _kataToHira(katakana);

      // no kanji or unknown reading ⇒ plain token
      if (!_hasKanji(surface) || reading == '*' || reading == surface) {
        out.add(RubyToken(surface, null));
        continue;
      }

      // split prefix/suffix okurigana
      out.addAll(_splitOkurigana(surface, reading));
    }
    return out;
  }

  /* ───────────────────── private helpers ───────────────────── */

  bool _hasKanji(String s) =>
      s.runes.any((r) => r >= 0x4E00 && r <= 0x9FFF);

  bool _isKana(int r) =>
      (r >= 0x3040 && r <= 0x309F) || (r >= 0x30A0 && r <= 0x30FF);

  /// break a mixed‑kanji token into [kana‑prefix][kanji‑core][kana‑suffix]
  /// and assign ruby only to the core.
  List<RubyToken> _splitOkurigana(String surface, String reading) {
    int pre = 0;
    while (pre < surface.length &&
        pre < reading.length &&
        surface.codeUnitAt(pre) == reading.codeUnitAt(pre) &&
        _isKana(surface.codeUnitAt(pre))) {
      pre++;
    }

    int suf = 0;
    while (suf < surface.length - pre &&
        suf < reading.length - pre &&
        surface.codeUnitAt(surface.length - 1 - suf) ==
            reading.codeUnitAt(reading.length - 1 - suf) &&
        _isKana(surface.codeUnitAt(surface.length - 1 - suf))) {
      suf++;
    }

    final List<RubyToken> list = [];

    if (pre > 0) {
      list.add(RubyToken(surface.substring(0, pre), null)); // kana prefix
    }

    final coreSurf = surface.substring(pre, surface.length - suf);
    final coreRead = reading.substring(pre, reading.length - suf);
    if (coreSurf.isNotEmpty) {
      list.add(RubyToken(coreSurf, coreRead)); // kanji with ruby
    }

    if (suf > 0) {
      list.add(
          RubyToken(surface.substring(surface.length - suf), null)); // suffix
    }
    return list;
  }

  String _kataToHira(String kata) => kata.replaceAllMapped(
        RegExp('[ァ-ヶ]'),
        (m) => String.fromCharCode(m[0]!.codeUnitAt(0) - 0x60),
      );
}