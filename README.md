# furigana

A Flutter package for annotating Japanese kanji with furigana (ruby text), powered by [MeCab](https://taku910.github.io/mecab/) and the IPADIC dictionary. Perfect for Japanese learning apps, readers, or any UI that needs to display kana readings above kanji.

## ✨ Features

- Converts raw Japanese text into annotated ruby tokens.
- Handles okurigana (kana attached to kanji) with high accuracy.
- Supports mixed readings including:
  - **Kunyomi** / **Onyomi**
  - **Jukujikun** (special compound readings)
  - **Ateji** and irregular readings
- Aligns per-kanji readings precisely, avoiding overgeneralized ruby spans.
- Falls back gracefully for unknown words or names.