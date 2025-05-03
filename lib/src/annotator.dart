import 'package:mecab_dart/mecab_dart.dart';
import 'package:characters/characters.dart';

class RubyToken {
  final String text;
  final String? ruby; // null = no furigana
  const RubyToken(this.text, this.ruby);
}

class FuriganaAnnotator {
  FuriganaAnnotator({String? dic})
      : _dic = dic ?? 'packages/furigana/assets/ipadic';

  final String _dic;
  late final Mecab _mecab;
  bool _ready = false;
  static final _cache = <String, List<String>>{};

  /* ─────────── init ─────────── */

  Future<void> init() async {
    _mecab = Mecab();
    await _mecab.init(_dic, true);
    _ready = true;
  }

  /* ─────────── public API ─────────── */

  Future<List<RubyToken>> tokenize(String sentence) async {
    if (!_ready) throw StateError('Call init() first');

    final mecabToks = _mecab.parse(sentence);
    final out = <RubyToken>[];

    for (final t in mecabToks) {
      if (t.surface == 'EOS') continue;

      final surf = t.surface;
      final rawRead = t.features.length > 7 ? t.features[7] : '*';
      final read = _kata2hira(rawRead);

      if (!_hasKanji(surf) || read == '*' || read == surf) {
        out.add(RubyToken(surf, null)); // kana / punctuation
        continue;
      }
      out.addAll(_processWord(surf, read));
    }
    return out;
  }

  /* ─────────── word → ruby tokens ─────────── */

  List<RubyToken> _processWord(String surface, String reading) {
    // 1. strip identical kana prefix/suffix (simple okurigana)
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

    final coreS = surface.substring(pre, surface.length - suf);
    final coreR = reading.substring(pre, reading.length - suf);

    if (coreS.isNotEmpty) {
      final aligned = _alignCore(coreS, coreR);
      out.addAll(aligned ?? [RubyToken(coreS, coreR)]); // fallback → jukujikun
    }

    if (suf > 0) out.add(RubyToken(surface.substring(surface.length - suf), null));
    return out;
  }

  /* ─────────── DP alignment ─────────── */

  /* ───────── align one word: exact per‑kanji ruby ───────── */

  List<RubyToken>? _alignCore(String kanjiSeq, String reading) {
    final chars = kanjiSeq.characters.toList();
    final nKanji = chars.length;

    // pre‑fetch dictionary readings for each kanji
    final dict = [
      for (final ch in chars)
        _isKana(ch.codeUnitAt(0)) ? <String>[ch] : _charReadings(ch)
    ];

    List<RubyToken>? dfs(int idxChar, int idxRead) {
      if (idxChar == nKanji && idxRead == reading.length) return [];

      if (idxChar >= nKanji || idxRead >= reading.length) return null;

      final ch = chars[idxChar];

      /* ---------- literal kana in surface ---------- */
      if (_isKana(ch.codeUnitAt(0))) {
        if (!reading.startsWith(ch, idxRead)) return null;
        final tail = dfs(idxChar + 1, idxRead + ch.length);
        return tail == null ? null : [RubyToken(ch, null), ...tail];
      }

      /* ---------- kanji: try dict readings ---------- */
      for (final r in dict[idxChar]) {
        if (!reading.startsWith(r, idxRead)) continue;
        final tail = dfs(idxChar + 1, idxRead + r.length);
        if (tail != null) return [RubyToken(ch, r), ...tail];
      }

      /* ---------- variable‑length fallback ---------- */
      final kanjiLeft = nKanji - idxChar - 1;
      final maxLen = reading.length - idxRead - kanjiLeft;
      // try longest first so we favour kun‑yomi like むすめ over む
      for (int len = maxLen; len >= 1; len--) {
        final slice = reading.substring(idxRead, idxRead + len);
        final tail = dfs(idxChar + 1, idxRead + len);
        if (tail != null) return [RubyToken(ch, slice), ...tail];
      }

      return null; // no path
    }

    return dfs(0, 0);
  }

  /* ─────────── per‑kanji readings via MeCab + cache ─────────── */

  List<String> _charReadings(String kanji) {
    if (_cache.containsKey(kanji)) return _cache[kanji]!;

    final parsed = _mecab.parse(kanji);
    final list = <String>{};

    for (final t in parsed) {
      if (t.surface == 'EOS') continue;
      final raw = t.features.length > 7 ? t.features[7] : '*';
      final hira = _kata2hira(raw);
      if (hira != '*' && hira != kanji) list.add(hira);
    }
    // sort by length (longest first) so DP chooses longer kana when possible
    final result = list.toList()..sort((a, b) => b.length - a.length);
    _cache[kanji] = result;
    return result;
  }

  /* ─────────── util helpers ─────────── */

  bool _isKana(int r) =>
      (r >= 0x3040 && r <= 0x309F) || (r >= 0x30A0 && r <= 0x30FF);

  bool _hasKanji(String s) =>
      s.runes.any((r) => r >= 0x4E00 && r <= 0x9FFF);

  String _kata2hira(String kata) => kata.replaceAllMapped(
        RegExp('[ァ-ヶ]'),
        (m) => String.fromCharCode(m[0]!.codeUnitAt(0) - 0x60),
      );
}