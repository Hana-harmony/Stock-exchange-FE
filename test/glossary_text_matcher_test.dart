import 'package:flutter_test/flutter_test.dart';
import 'package:stock_exchange_fe/src/core/glossary_text_matcher.dart';

void main() {
  test('does not match a glossary term inside another English token', () {
    const text = 'significant participant antitrust advantage';

    expect(GlossaryTextMatcher.findWholeTermStart(text, 'ant'), -1);
    expect(GlossaryTextMatcher.findWholeTermStart(text, 'part'), -1);
    expect(GlossaryTextMatcher.findWholeTermStart(text, 'age'), -1);
  });

  test('matches standalone terms case-insensitively', () {
    const text = 'An Ant, a Daejangju, and Bittu appeared.';

    expect(GlossaryTextMatcher.findWholeTermStart(text, 'ant'), 3);
    expect(GlossaryTextMatcher.findWholeTermStart(text, 'daejangju'), 10);
    expect(GlossaryTextMatcher.findWholeTermStart(text, 'BITTU'), 25);
  });

  test('checks every occurrence until a whole token is found', () {
    const text = 'participant behavior changed; an ant bought shares';

    expect(GlossaryTextMatcher.findWholeTermStart(text, 'ant'), 33);
  });

  test('keeps Korean glossary surface matching behavior', () {
    const text = '동학개미와 개미 투자자';

    expect(GlossaryTextMatcher.findWholeTermStart(text, '개미'), 2);
  });
}
