import 'package:flutter/material.dart';

/// 经典 2048 配色。超出表格范围的高数值统一使用最深色。
const Map<int, Color> _tileColors = <int, Color>{
  2: Color(0xFFEEE4DA),
  4: Color(0xFFEDE0C8),
  8: Color(0xFFF2B179),
  16: Color(0xFFF59563),
  32: Color(0xFFF67C5F),
  64: Color(0xFFF65E3B),
  128: Color(0xFFEDCF72),
  256: Color(0xFFEDCC61),
  512: Color(0xFFEDC850),
  1024: Color(0xFFEDC53F),
  2048: Color(0xFFEDC22E),
};

Color colorForValue(int value) => _tileColors[value] ?? const Color(0xFF3C3A32);

Color textColorForValue(int value) =>
    value <= 4 ? const Color(0xFF776E65) : Colors.white;

double fontSizeForValue(int value, double cellSize) {
  final digits = value.toString().length;
  final scale = switch (digits) {
    1 || 2 => 0.42,
    3 => 0.34,
    4 => 0.27,
    _ => 0.22,
  };
  return cellSize * scale;
}
