import 'package:collection/collection.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:mecab_dart/mecab_dart.dart';

/// One base string + its ruby reading (or `null` if no ruby needed).
class RubySegment {
  final String surface;
  final String? reading; // null ⇒ show surface only

  const RubySegment(this.surface, [this.reading]);

  bool get needsRuby => reading != null && reading != surface;
}

/// The heavy‑lifter: runs MeCab and aligns kana readings to kanji.
class FuriganaAnnotator {
  FuriganaAnnotator({required this.dictionaryDir});

  final String dictionaryDir;
  late final Mecab _mecab;
  bool _ready = false;

  /// Initialise MeCab (call **once**, e.g. in `main()`).
  Future<void> init() async {
    _mecab = Mecab();
    await _mecab.init(dictionaryDir, true /* want features */);
    _ready = true;
  }

  /// Parse Japanese text → list of [RubySegment]s.
  Future<List<RubySegment>> annotate(String text) async {
    if (!_ready) throw StateError('Call init() first.');
    final tokens = _mecab.parse(text);
    final List<RubySegment> segments = [];

    for (final token in tokens) {
      if (token.surface == 'EOS') continue;

      // Mecab feature layout for IPADIC:
      // 0: POS, 1–3: sub‑POS, 4: conjugation type, 5: form,
      // 6: lemma (基本形), 7: reading (カナ), 8: pronunciation
      final readingKatakana =
          token.features.length > 7 ? token.features[7] : '*';

      final surface = token.surface;
      final readingHiragana = _katakanaToHiragana(readingKatakana);

      // Decide whether furigana is required for this token.
      final needsRuby = _containsKanji(surface) &&
          readingHiragana != '*' &&
          readingHiragana != surface;

      if (!needsRuby) {
        segments.add(RubySegment(surface)); // plain text
      } else {
        // Try to split reading so kana already present in the surface
        // appear in‑line, and furigana is shown only above kanji.
        segments.addAll(_align(surface, readingHiragana));
      }
    }
    return segments;
  }

  /* ------------------------------------------------------------------ */
  // --------------- private helpers ---------------------------------- */

  bool _containsKanji(String s) =>
      s.runes.any((r) => (r >= 0x4E00 && r <= 0x9FFF));

  /// Simple longest‑common‑prefix/suffix heuristic.
  ///
  /// For 勉強(べんきょう) → ["勉強", "べんきょう"]
  /// For 今日(きょう)    → ["今", "きょ"], ["日", "う"]  (not perfect but OK)
  /// If it fails, fall back to whole‑token ruby.
  List<RubySegment> _align(String surface, String reading) {
    // If surface contains kana, strip matching prefix/suffix from reading.
    final kanaPrefix = _commonPrefix(surface, reading);
    final kanaSuffix = _commonSuffix(surface, reading);
    final List<RubySegment> segments = [];

    var coreSurface = surface;
    var coreReading = reading;

    if (kanaPrefix.isNotEmpty) {
      segments.add(RubySegment(kanaPrefix)); // in‑line prefix
      coreSurface = coreSurface.substring(kanaPrefix.length);
      coreReading = coreReading.substring(kanaPrefix.length);
    }
    if (kanaSuffix.isNotEmpty) {
      coreSurface =
          coreSurface.substring(0, coreSurface.length - kanaSuffix.length);
      coreReading =
          coreReading.substring(0, coreReading.length - kanaSuffix.length);
    }

    if (coreSurface.isEmpty) {
      // Entire token was kana → no ruby needed
      return [RubySegment(surface)];
    }

    final List<RubySegment> result = [];
    if (coreSurface.isNotEmpty) {
      result.add(RubySegment(coreSurface, coreReading));
    }
    if (kanaSuffix.isNotEmpty) result.add(RubySegment(kanaSuffix));
    return result;
  }

  String _commonPrefix(String a, String b) {
    final minLen = a.length < b.length ? a.length : b.length;
    for (var i = 0; i < minLen; i++) {
      if (a[i] != b[i]) return a.substring(0, i);
    }
    return a.substring(0, minLen);
  }

  String _commonSuffix(String a, String b) {
    final minLen = a.length < b.length ? a.length : b.length;
    for (var i = 1; i <= minLen; i++) {
      if (a[a.length - i] != b[b.length - i]) return a.substring(a.length - i + 1);
    }
    return a.substring(a.length - minLen);
  }

  String _katakanaToHiragana(String kata) => kata.replaceAllMapped(
        RegExp('[ァ-ヶ]'),
        (m) => String.fromCharCode(m[0]!.codeUnitAt(0) - 0x60),
      );
}