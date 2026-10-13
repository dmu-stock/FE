/// Number formatting shared by the portfolio screens.
///
/// The backend prices US stocks in USD, so the app's original 원 formatting no
/// longer applies. Hand-rolled rather than pulling in `intl` for two helpers.
library;

/// `1234567.5` → `"1,234,567"`
String thousands(num value) {
  final negative = value < 0;
  final digits = value.abs().truncate().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    buffer.write(digits[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
  }
  return negative ? '-$buffer' : buffer.toString();
}

/// `219.34` → `"$219.34"`. Drops the cents once the number is large enough
/// that they are noise.
String formatUsd(num value, {bool cents = true}) {
  final negative = value < 0;
  final abs = value.abs();
  final sign = negative ? '-' : '';
  if (!cents || abs >= 100000) return '$sign\$${thousands(abs)}';
  final whole = abs.truncate();
  final fraction = ((abs - whole) * 100).round().clamp(0, 99);
  return '$sign\$${thousands(whole)}.${fraction.toString().padLeft(2, '0')}';
}

/// `3.14` → `"+3.14%"`
String formatPercent(num value, {int decimals = 2}) {
  final sign = value > 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(decimals)}%';
}

/// Quantities arrive as `number`; show `4` rather than `4.0`, but keep a
/// fractional share visible if there is one.
String formatShares(double quantity) {
  if (quantity == quantity.roundToDouble()) return thousands(quantity);
  return quantity.toStringAsFixed(2);
}
