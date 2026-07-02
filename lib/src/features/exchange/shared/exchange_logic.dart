part of '../exchange_pages.dart';

String marketQuoteLiveStatusLabel(
  MarketQuoteLiveStatus liveStatus,
  MarketQuote? quote, {
  DateTime? nowUtc,
}) {
  final now = (nowUtc ?? DateTime.now()).toUtc().add(const Duration(hours: 9));
  final minutes = now.hour * 60 + now.minute;
  final isWeekday =
      now.weekday >= DateTime.monday && now.weekday <= DateTime.friday;
  final isRegularHours = isWeekday && minutes >= 540 && minutes < 930;
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

String _formatNumber(int value) {
  final digits = '$value';
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    final remaining = digits.length - index;
    buffer.write(digits[index]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

String? _formatMarketStatus(DateTime? marketDataTime) {
  if (marketDataTime == null) {
    return null;
  }
  return formatKoreanMarketClosedLabel(marketDataTime);
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
  return _formatNumber(value);
}
