part of '../exchange_pages.dart';

const _monthLabels = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String formatEtWithKst(DateTime? value) {
  if (value == null) {
    return 'Time unavailable';
  }
  final utc = value.toUtc();
  final eastern = _toUsEastern(utc);
  final kst = utc.add(const Duration(hours: 9));
  return '${_formatDateTime(eastern.local, eastern.suffix)} '
      '(${_formatDateTime(kst, 'KST')})';
}

String formatKoreanMarketClosedLabel(DateTime? marketDataTime) {
  if (marketDataTime == null) {
    return 'Market status loading';
  }
  final kst = marketDataTime.toUtc().add(const Duration(hours: 9));
  final closeKst = DateTime.utc(
    kst.year,
    kst.month,
    kst.day,
    6,
    30,
  );
  return 'Market Closed ${formatEtWithKst(closeKst)}';
}

_EasternTime _toUsEastern(DateTime utc) {
  final dstStart = _secondSundayOfMarchUtc(utc.year);
  final dstEnd = _firstSundayOfNovemberUtc(utc.year);
  final isDst = !utc.isBefore(dstStart) && utc.isBefore(dstEnd);
  final offset = isDst ? const Duration(hours: -4) : const Duration(hours: -5);
  return _EasternTime(utc.add(offset), isDst ? 'ET' : 'ET');
}

DateTime _secondSundayOfMarchUtc(int year) {
  final firstDay = DateTime.utc(year, DateTime.march);
  final firstSundayOffset = (DateTime.sunday - firstDay.weekday) % 7;
  final day = 1 + firstSundayOffset + 7;
  return DateTime.utc(year, DateTime.march, day, 7);
}

DateTime _firstSundayOfNovemberUtc(int year) {
  final firstDay = DateTime.utc(year, DateTime.november);
  final firstSundayOffset = (DateTime.sunday - firstDay.weekday) % 7;
  final day = 1 + firstSundayOffset;
  return DateTime.utc(year, DateTime.november, day, 6);
}

String _formatDateTime(DateTime value, String suffix) {
  final hour12 = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final ampm = value.hour < 12 ? 'AM' : 'PM';
  return '${_monthLabels[value.month - 1]} ${value.day}, ${value.year} '
      '$hour12:$minute $ampm $suffix';
}

class _EasternTime {
  const _EasternTime(this.local, this.suffix);

  final DateTime local;
  final String suffix;
}
