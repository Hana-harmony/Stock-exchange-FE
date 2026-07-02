String formatCurrencyDisplay(String currency, String amount) {
  return '$currency ${formatCurrencyAmount(currency, amount)}';
}

String formatCurrencyAmount(String currency, String amount) {
  if (currency.trim().toUpperCase() != 'USD') {
    return amount;
  }
  return formatUsdAmount(amount);
}

String formatUsdAmount(String amount) {
  final trimmed = amount.trim();
  if (trimmed.isEmpty) {
    return amount;
  }

  final sign = switch (trimmed[0]) {
    '+' => '+',
    '-' => '-',
    _ => '',
  };
  final unsigned = sign.isEmpty ? trimmed : trimmed.substring(1);
  final normalized = unsigned.replaceAll(',', '');
  if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(normalized)) {
    return amount;
  }

  final parts = normalized.split('.');
  final whole = _formatThousands(parts.first);
  final fraction = parts.length > 1 ? parts[1] : '';
  final cents = fraction.padRight(2, '0').substring(0, 2);
  return '$sign$whole.$cents';
}

String _formatThousands(String digits) {
  final normalized = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
  final buffer = StringBuffer();

  for (var index = 0; index < normalized.length; index++) {
    if (index > 0 && (normalized.length - index) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(normalized[index]);
  }

  return buffer.toString();
}
