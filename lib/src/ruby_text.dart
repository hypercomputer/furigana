import 'package:flutter/widgets.dart';
import 'annotator.dart';

/// Renders a list of [RubySegment]s in one `RichText`.
class RubyText extends StatelessWidget {
  const RubyText(
    this.segments, {
    super.key,
    this.style,
    this.rubyStyle,
    this.spacing = 2,
  });

  final List<RubySegment> segments;
  final TextStyle? style;
  final TextStyle? rubyStyle;
  final double spacing; // vertical gap in logical px

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final ruby =
        rubyStyle ?? baseStyle.copyWith(fontSize: baseStyle.fontSize! * 0.5);

    return RichText(
      text: TextSpan(
        children: segments.map<InlineSpan>((seg) {
          if (!seg.needsRuby) {
            return TextSpan(text: seg.surface, style: baseStyle);
          }
          return WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.ideographic,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(seg.reading!, style: ruby),
                SizedBox(height: spacing),
                Text(seg.surface, style: baseStyle),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}