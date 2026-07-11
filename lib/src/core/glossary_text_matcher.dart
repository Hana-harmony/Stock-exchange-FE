class GlossaryTextMatcher {
  const GlossaryTextMatcher._();

  static int findWholeTermStart(
    String text,
    String term, {
    int start = 0,
  }) {
    if (term.isEmpty || start < 0 || start >= text.length) {
      return -1;
    }

    final normalizedText = text.toLowerCase();
    final normalizedTerm = term.toLowerCase();
    var candidateStart = normalizedText.indexOf(normalizedTerm, start);
    while (candidateStart != -1) {
      final candidateEnd = candidateStart + normalizedTerm.length;
      if (_hasTokenBoundaries(
        text: normalizedText,
        term: normalizedTerm,
        start: candidateStart,
        end: candidateEnd,
      )) {
        return candidateStart;
      }
      candidateStart = normalizedText.indexOf(
        normalizedTerm,
        candidateStart + 1,
      );
    }
    return -1;
  }

  static bool _hasTokenBoundaries({
    required String text,
    required String term,
    required int start,
    required int end,
  }) {
    final first = term.codeUnitAt(0);
    final last = term.codeUnitAt(term.length - 1);
    final leftBlocked = _isAsciiAlphaNumeric(first) &&
        start > 0 &&
        _isAsciiAlphaNumeric(text.codeUnitAt(start - 1));
    final rightBlocked = _isAsciiAlphaNumeric(last) &&
        end < text.length &&
        _isAsciiAlphaNumeric(text.codeUnitAt(end));
    return !leftBlocked && !rightBlocked;
  }

  static bool _isAsciiAlphaNumeric(int codeUnit) {
    return (codeUnit >= 48 && codeUnit <= 57) ||
        (codeUnit >= 97 && codeUnit <= 122);
  }
}
