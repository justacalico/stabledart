import 'package:intl/intl.dart';

enum NumberFormatMode {
  comma,
  period,
  space,
  none;

  String get displayName => switch (this) {
    NumberFormatMode.comma => 'Comma',
    NumberFormatMode.period => 'Period',
    NumberFormatMode.space => 'Space',
    NumberFormatMode.none => 'None',
  };

  String get sample => switch (this) {
    NumberFormatMode.comma => '1,234,567',
    NumberFormatMode.period => '1.234.567',
    NumberFormatMode.space => '1 234 567',
    NumberFormatMode.none => '1234567',
  };

  static NumberFormatMode fromName(String? name) => values.firstWhere(
    (m) => m.name == name,
    orElse: () => NumberFormatMode.comma,
  );
}

String formatNumber(int value, NumberFormatMode mode) {
  switch (mode) {
    case NumberFormatMode.none:
      return value.toString();
    case NumberFormatMode.comma:
      return NumberFormat('#,###', 'en_US').format(value);
    case NumberFormatMode.period:
      return NumberFormat('#,###', 'en_US').format(value).replaceAll(',', '.');
    case NumberFormatMode.space:
      return NumberFormat('#,###', 'en_US').format(value).replaceAll(',', ' ');
  }
}
