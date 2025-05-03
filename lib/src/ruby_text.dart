import 'package:flutter/widgets.dart';
import 'annotator.dart';

class RubyText extends StatelessWidget {
  const RubyText(
    this.segments, {
    super.key,
    this.style,
    this.rubyStyle,
    this.gap = 2,
  });

  final List<RubySegment> segments;
  final TextStyle? style;
  final TextStyle? rubyStyle;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    final ruby =
        rubyStyle ?? base.copyWith(fontSize: base.fontSize! * 0.55);

    final children = segments.map((seg) {
      // Reusable widget for *every* token so heights match.
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (seg.needsRuby) Text(seg.reading!, style: ruby),
            if (seg.needsRuby) SizedBox(height: gap),
            Text(seg.surface, style: base),
          ],
        ),
      );
    }).toList();

    return RichText(
      text: TextSpan(
        children: children
            .map((w) => WidgetSpan(
                  alignment: PlaceholderAlignment.top,
                  child: w,
                ))
            .toList(),
      ),
    );
  }
}