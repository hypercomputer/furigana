import 'package:mecab_dart/mecab_dart.dart';

class RubySegment {
  final String surface;
  final String? reading;
  const RubySegment(this.surface, [this.reading]);
  bool get needsRuby => reading != null && reading != surface;
}

class FuriganaAnnotator {
  /// If the caller gives no path, fall back to the package asset.
  FuriganaAnnotator({String? dictionaryDir})
      : dictionaryDir =
            dictionaryDir ?? 'packages/furigana/assets/ipadic';

  final String dictionaryDir;
  late final Mecab _mecab;
  bool _ready = false;

  Future<void> init() async {
    _mecab = Mecab();
    await _mecab.init(dictionaryDir, true);
    _ready = true;
  }

  Future<List<RubySegment>> annotate(String text) async {
    if (!_ready) throw StateError('Call init() first.');
    final tokens = _mecab.parse(text);
    final List<RubySegment> out = [];

    for (final t in tokens) {
      if (t.surface == 'EOS') continue;

      final surface = t.surface;
      final kana = t.features.length > 7 ? t.features[7] : '*';
      final reading = _katakanaToHiragana(kana);

      final needsRuby = _hasKanji(surface) &&
          reading != '*' &&
          reading != surface;

      out.addAll(
        needsRuby ? _align(surface, reading) : [RubySegment(surface)],
      );
    }
    return out;
  }

  /* ---------- helpers ---------- */

  bool _hasKanji(String s) =>
      s.runes.any((r) => r >= 0x4E00 && r <= 0x9FFF);

  List<RubySegment> _align(String surface, String reading) {
    final prefix = _commonPrefix(surface, reading);
    final suffix = _commonSuffix(surface, reading);

    final List<RubySegment> segs = [];
    var s = surface, r = reading;

    if (prefix.isNotEmpty) {
      segs.add(RubySegment(prefix));
      s = s.substring(prefix.length);
      r = r.substring(prefix.length);
    }
    if (suffix.isNotEmpty) {
      s = s.substring(0, s.length - suffix.length);
      r = r.substring(0, r.length - suffix.length);
    }

    if (s.isNotEmpty) segs.add(RubySegment(s, r));
    if (suffix.isNotEmpty) segs.add(RubySegment(suffix));
    return segs;
  }

  String _katakanaToHiragana(String kata) => kata.replaceAllMapped(
        RegExp('[ァ-ヶ]'),
        (m) => String.fromCharCode(m[0]!.codeUnitAt(0) - 0x60),
      );

  String _commonPrefix(String a, String b) {
    for (var i = 0; i < a.length && i < b.length; i++) {
      if (a[i] != b[i]) return a.substring(0, i);
    }
    return a.length < b.length ? a : b;
  }

  String _commonSuffix(String a, String b) {
    for (var i = 1;
        i <= a.length && i <= b.length && a[a.length - i] == b[b.length - i];
        i++) {
      if (i == a.length || i == b.length) return a.substring(a.length - i);
    }
    return '';
  }
}