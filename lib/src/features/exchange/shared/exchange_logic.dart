part of '../exchange_pages.dart';

const _koreanRegularOpenMinutes = 9 * 60;
const _koreanRegularCloseMinutes = 15 * 60 + 30;

String marketQuoteLiveStatusLabel(
  MarketQuoteLiveStatus liveStatus,
  MarketQuote? quote, {
  DateTime? nowUtc,
}) {
  final now = (nowUtc ?? DateTime.now()).toUtc().add(const Duration(hours: 9));
  final minutes = now.hour * 60 + now.minute;
  final isWeekday = _isKoreanRegularSessionWeekday(now);
  final isRegularHours = isWeekday &&
      minutes >= _koreanRegularOpenMinutes &&
      minutes < _koreanRegularCloseMinutes;
  if (!isRegularHours) {
    return 'Closed';
  }
  switch (liveStatus) {
    case MarketQuoteLiveStatus.connecting:
      return 'Connecting';
    case MarketQuoteLiveStatus.live:
      return quote == null ? 'Live' : 'Live ${quote.market}';
    case MarketQuoteLiveStatus.failure:
      return 'Reconnect';
    case MarketQuoteLiveStatus.disconnected:
      return 'Paused';
  }
}

String _relativeTimeLabel(DateTime? timestamp) {
  if (timestamp == null) {
    return '1h ago';
  }
  final now = DateTime.now().toUtc();
  final diff = now.difference(timestamp.toUtc());
  if (diff.inMinutes < 1) {
    return 'Now';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes}m ago';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours}h ago';
  }
  if (diff.inDays < 7) {
    return '${diff.inDays}d ago';
  }
  return '${timestamp.month}/${timestamp.day}';
}

String _companyLabel(String stockName) {
  final trimmed = stockName.trim();
  if (trimmed.isEmpty) {
    return 'Samsung';
  }
  final pieces = trimmed.split(RegExp(r'\s+'));
  return pieces.first;
}

bool _isHongKongMarket(String market) {
  final normalized = market.toUpperCase();
  return normalized.contains('HK') || normalized.contains('HANG');
}

String? _formatMarketStatus(DateTime? marketDataTime, {DateTime? nowUtc}) {
  if (marketDataTime == null) {
    return null;
  }
  return formatKoreanMarketClosedLabel(marketDataTime, nowUtc: nowUtc);
}

String _formatSignedCurrencyDifference(
  String currency,
  String current,
  String previous,
) {
  final currentValue = double.tryParse(current.replaceAll(',', '').trim());
  final previousValue = double.tryParse(previous.replaceAll(',', '').trim());
  if (currentValue == null || previousValue == null) {
    return '--';
  }
  final difference = currentValue - previousValue;
  final sign = difference > 0
      ? '+'
      : difference < 0
          ? '-'
          : '';
  return '$sign${formatCurrencyDisplay(currency, difference.abs().toStringAsFixed(2))}';
}

String _formatRange(String? min, String? max, String fallback) {
  if (min == null || max == null || min.isEmpty || max.isEmpty) {
    return fallback;
  }
  return '$min%~$max%';
}

double _parsePercent(String value) {
  return double.tryParse(value.replaceAll('%', '').trim()) ?? 0;
}

String _formatCompactNumber(int value) {
  if (value < 1000000) {
    return _formatWholeNumber(value);
  }
  final millions = value / 1000000;
  final formatted = millions >= 10
      ? millions.toStringAsFixed(1)
      : millions.toStringAsFixed(2);
  return '${_trimTrailingZeros(formatted)}M';
}

String _formatWholeNumber(int value) {
  final sign = value < 0 ? '-' : '';
  final digits = value.abs().toString();
  final buffer = StringBuffer(sign);
  for (var index = 0; index < digits.length; index++) {
    final remaining = digits.length - index;
    buffer.write(digits[index]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

String _trimTrailingZeros(String value) {
  if (!value.contains('.')) {
    return value;
  }
  return value.replaceFirst(RegExp(r'\.?0+$'), '');
}

bool _isKoreanRegularSessionWeekday(DateTime kst) {
  return kst.weekday >= DateTime.monday && kst.weekday <= DateTime.friday;
}

DateTime _koreanDateOnly(DateTime kst) {
  return DateTime.utc(kst.year, kst.month, kst.day);
}

DateTime _lastKoreanRegularSessionDate(DateTime now) {
  final kst = now.toUtc().add(const Duration(hours: 9));
  final minutes = kst.hour * 60 + kst.minute;
  var sessionDate = _koreanDateOnly(kst);

  // 한국장은 KST 날짜와 정규장 시작 시간을 기준으로 마지막 세션을 고정한다.
  if (!_isKoreanRegularSessionWeekday(kst) ||
      minutes < _koreanRegularOpenMinutes) {
    sessionDate = sessionDate.subtract(const Duration(days: 1));
  }
  while (!_isKoreanRegularSessionWeekday(sessionDate)) {
    sessionDate = sessionDate.subtract(const Duration(days: 1));
  }
  return sessionDate;
}
