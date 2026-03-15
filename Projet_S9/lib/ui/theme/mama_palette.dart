import 'package:flutter/material.dart';

enum MamaThemeColor { blue, pink, purple, orange, green, red, brown }

class MamaColorPair {
  final Color primary;
  final Color secondary;

  const MamaColorPair(this.primary, this.secondary);
}

const mamaThemeColors = {
  MamaThemeColor.blue: MamaColorPair(Color(0xFF4F7CFF), Color(0xFF9CC5FF)),

  MamaThemeColor.pink: MamaColorPair(Color(0xFFE85D8F), Color(0xFFFFCCDD)),

  MamaThemeColor.purple: MamaColorPair(Color(0xFFB46ABF), Color(0xFFF3D7F3)),

  MamaThemeColor.orange: MamaColorPair(Color(0xFFF29A4B), Color(0xFFFFE5CC)),

  MamaThemeColor.green: MamaColorPair(Color(0xFF2FBF9A), Color(0xFFCCF9E6)),

  MamaThemeColor.red: MamaColorPair(Color(0xFFE86A4F), Color(0xFFFFD9CC)),

  MamaThemeColor.brown: MamaColorPair(Color(0xFF8A6A3D), Color(0xFFD4C4A8)),
};
