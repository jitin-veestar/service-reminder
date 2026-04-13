import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const primary = Color(0xFF1E88E5);
  static const primaryLight = Color(0xFF6AB7FF);
  static const primaryDark = Color(0xFF005CB2);

  // Surfaces
  static const background = Color(0xFFF5F7FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFEEF2F7);

  // Semantic
  static const error = Color(0xFFE53935);
  static const success = Color(0xFF43A047);
  static const warning = Color(0xFFFB8C00);

  // Text
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const textHint = Color(0xFFBDBDBD);

  // Borders / dividers
  static const divider = Color(0xFFE0E0E0);
  static const border = Color(0xFFD1D9E6);

  // Service status chips
  static const overdue = Color(0xFFE53935);   // red
  static const dueSoon = Color(0xFFFB8C00);   // orange
  static const upToDate = Color(0xFF43A047);  // green
}
