import 'package:mecab_dart/mecab_dart.dart';
import 'package:characters/characters.dart';

class RubyToken {
  final String text;
  final String? ruby;          // null = no furigana
  const RubyToken(this.text, this.ruby);
}

class FuriganaAnnotator {
  FuriganaAnnotator({String? dic})
      : _dic = dic ?? 'packages/furigana/assets/ipadic';

  final String _dic;
  late final Mecab _mecab;
  bool _ready = false;
  static final _cache = <String, List<String>>{};

  /* ───────── init ───────── */

  Future<void> init() async {
    _mecab = Mecab();
    await _mecab.init(_dic, true);
    _ready = true;
  }

  /* ───────── public API ───────── */

  Future<List<RubyToken>> tokenize(String sentence) async {
    if (!_ready) throw StateError('Call init() first');

    final out = <RubyToken>[];
    for (final t in _mecab.parse(sentence)) {
      if (t.surface == 'EOS') continue;

      final surf = t.surface;
      final raw   = t.features.length > 7 ? t.features[7] : '*';
      final read  = _kata2hira(raw);

      if (!_hasKanji(surf) || read == '*' || read == surf) {
        out.add(RubyToken(surf, null));
      } else {
        out.addAll(_processWord(surf, read));
      }
    }
    return out;
  }

  /* ───────── strip outer okurigana, then align core ───────── */

  List<RubyToken> _processWord(String surf, String read) {
    int pre = 0, suf = 0;

    while (pre < surf.length &&
        pre < read.length &&
        surf.codeUnitAt(pre) == read.codeUnitAt(pre) &&
        _isKana(surf.codeUnitAt(pre))) pre++;

    while (suf < surf.length - pre &&
        suf < read.length - pre &&
        surf.codeUnitAt(surf.length - 1 - suf) ==
            read.codeUnitAt(read.length - 1 - suf) &&
        _isKana(surf.codeUnitAt(surf.length - 1 - suf))) suf++;

    final tokens = <RubyToken>[];
    if (pre > 0) tokens.add(RubyToken(surf.substring(0, pre), null));

    final coreS = surf.substring(pre, surf.length - suf);
    final coreR = read.substring(pre, read.length - suf);

    if (coreS.isNotEmpty) {
      tokens.addAll(_alignCore(coreS, coreR) ?? [RubyToken(coreS, coreR)]);
    }
    if (suf > 0) tokens.add(RubyToken(surf.substring(surf.length - suf), null));

    return tokens;
  }

  /* ───────── exact per‑kanji alignment ───────── */

  List<RubyToken>? _alignCore(String kanjiSeq, String reading) {
    final chars   = kanjiSeq.characters.toList();
    final n       = chars.length;
    final hasKana = chars.any((c) => _isKana(c.codeUnitAt(0)));

    final dict = [
      for (final ch in chars)
        _isKana(ch.codeUnitAt(0)) ? <String>[ch] : _charReadings(ch)
    ];

    List<RubyToken>? dfs(int iChar, int iRead) {
      if (iChar == n && iRead == reading.length) return [];
      if (iChar >= n || iRead >= reading.length) return null;

      final ch = chars[iChar];

      /* literal kana in surface */
      if (_isKana(ch.codeUnitAt(0))) {
        if (!reading.startsWith(ch, iRead)) return null;
        final tail = dfs(iChar + 1, iRead + ch.length);
        return tail == null ? null : [RubyToken(ch, null), ...tail];
      }

      /* dictionary readings */
      for (final r in dict[iChar]) {
        if (!reading.startsWith(r, iRead)) continue;
        final tail = dfs(iChar + 1, iRead + r.length);
        if (tail != null) return [RubyToken(ch, r), ...tail];
      }

      /* variable‑length fallback (1..max) */
      final kanjiLeft = n - iChar - 1;
      final maxLen    = reading.length - iRead - kanjiLeft;
      if (maxLen <= 0) return null;

      for (int len = 1; len <= maxLen; len++) {        // shortest → longest
        final slice = reading.substring(iRead, iRead + len);
        final tail  = dfs(iChar + 1, iRead + len);
        if (tail != null) return [RubyToken(ch, slice), ...tail];
      }
      return null;
    }

    final path = dfs(0, 0);
    if (path == null) return null;           // should fall back to jukujikun

    /* ---- validate path so jukujikun stay whole ---- */
    final usedDict = path.any((tok) {
      final idx = path.indexOf(tok);
      return tok.ruby != null &&
          dict[idx].contains(tok.ruby);      // came from dictionary
    });

    if (hasKana || usedDict) return path;    // good split
    final allOneKana = path.every((tok) => tok.ruby != null && tok.ruby!.length == 1);
    return (reading.length == n && allOneKana) ? path : null;
  }

  /* ───────── per‑kanji reading list via MeCab (+cache) ───────── */

  List<String> _charReadings(String kanji) {
    if (_cache.containsKey(kanji)) return _cache[kanji]!;

    final parsed = _mecab.parse(kanji);
    final set = <String>{};

    for (final t in parsed) {
      if (t.surface == 'EOS') continue;
      final raw  = t.features.length > 7 ? t.features[7] : '*';
      final hira = _kata2hira(raw);
      if (hira != '*' && hira != kanji) set.add(hira);
    }
    final list = set.toList()..sort((a, b) => b.length - a.length);
    _cache[kanji] = list;
    return list;
  }

  /* ───────── util helpers ───────── */

  bool _isKana(int r) =>
      (r >= 0x3040 && r <= 0x309F) || (r >= 0x30A0 && r <= 0x30FF);

  bool _hasKanji(String s) =>
      s.runes.any((r) => r >= 0x4E00 && r <= 0x9FFF);

  String _kata2hira(String kata) => kata.replaceAllMapped(
        RegExp('[ァ-ヶ]'),
        (m) => String.fromCharCode(m[0]!.codeUnitAt(0) - 0x60),
      );
}