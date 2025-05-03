import 'package:mecab_dart/mecab_dart.dart';
import 'package:characters/characters.dart';

class RubyToken {
  final String text;
  final String? ruby;
  const RubyToken(this.text, this.ruby);
}

class FuriganaAnnotator {
  FuriganaAnnotator({String? dic})
      : _dic = dic ?? 'packages/furigana/assets/ipadic';

  final String _dic;
  late final Mecab _mecab;
  bool _ready = false;

  /* -------------- public -------------- */

  Future<void> init() async {
    _mecab = Mecab();
    await _mecab.init(_dic, true);
    _ready = true;
  }

  Future<List<RubyToken>> tokenize(String sentence) async {
    if (!_ready) throw StateError('call init() first');

    final mecabToks = _mecab.parse(sentence);
    final out = <RubyToken>[];

    for (final tok in mecabToks) {
      if (tok.surface == 'EOS') continue;

      final surf = tok.surface;
      final read = _kata2hira(
          tok.features.length > 7 ? tok.features[7] : '*');

      if (!_hasKanji(surf) || read == '*' || read == surf) {
        out.add(RubyToken(surf, null));
        continue;
      }
      out.addAll(_splitAndAlign(surf, read));
    }
    return out;
  }

  /* -------------- splitting & alignment -------------- */

  List<RubyToken> _splitAndAlign(String surface, String reading) {
    // strip identical kana prefix/suffix (= okurigana outside)
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

    final out = <RubyToken>[];
    if (pre > 0) out.add(RubyToken(surface.substring(0, pre), null));

    final coreSurf = surface.substring(pre, surface.length - suf);
    final coreRead = reading.substring(pre, reading.length - suf);
    if (coreSurf.isNotEmpty) out.addAll(_alignCore(coreSurf, coreRead));

    if (suf > 0) {
      out.add(RubyToken(surface.substring(surface.length - suf), null));
    }
    return out;
  }

  List<RubyToken> _alignCore(String kanjiSeq, String reading) {
    var rIdx = 0;
    final toks = <RubyToken>[];

    for (final char in kanjiSeq.characters) {
      if (_isKana(char.codeUnitAt(0))) {
        toks.add(RubyToken(char, null));
        rIdx += char.length;
        continue;
      }

      final candList = _charReadings(char);
      String slice = '';

      for (final c in candList) {
        if (reading.startsWith(c, rIdx)) {
          slice = c;
          break;
        }
      }
      // fallback: at least one kana
      if (slice.isEmpty) slice = reading[rIdx];
      toks.add(RubyToken(char, slice));
      rIdx += slice.length;
    }
    return toks;
  }

  /* -------------- per‑kanji reading via MeCab -------------- */

  static final Map<String, List<String>> _cache = {};

  List<String> _charReadings(String kanji) {
    if (_cache.containsKey(kanji)) return _cache[kanji]!;

    final parsed = _mecab.parse(kanji);
    final list = <String>[];

    for (final t in parsed) {
      if (t.surface == 'EOS') continue;
      final r = t.features.length > 7 ? t.features[7] : '*';
      final hira = _kata2hira(r);
      if (hira != '*' && hira != kanji) list.add(hira);
    }
    _cache[kanji] = list;
    return list;
  }

  /* -------------- utilities -------------- */

  bool _hasKanji(String s) =>
      s.runes.any((r) => r >= 0x4E00 && r <= 0x9FFF);

  bool _isKana(int r) =>
      (r >= 0x3040 && r <= 0x309F) || (r >= 0x30A0 && r <= 0x30FF);

  String _kata2hira(String kata) => kata.replaceAllMapped(
        RegExp('[ァ-ヶ]'),
        (m) => String.fromCharCode(m[0]!.codeUnitAt(0) - 0x60),
      );
}