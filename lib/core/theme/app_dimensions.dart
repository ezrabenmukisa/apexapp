import 'package:flutter/widgets.dart';

/// 4-pt spacing scale, radii and touch targets (docs: 01 Foundations).
abstract final class AppDimensions {
  // Spacing
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s48 = 48;

  /// Horizontal padding for full-screen layouts.
  static const double screenGutter = 20;
  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(20, 12, 20, 24);

  // Radius — "a record, not a toy": nothing fully round except avatars.
  static const double radiusChip = 4;
  static const double radiusControl = 8;
  static const double radiusCard = 14;

  // Touch targets — gloved, dusty thumbs on site.
  static const double minTouchTarget = 48;
  static const double buttonHeight = 56;
  static const double secondaryButtonHeight = 52;
  static const double inputHeight = 48;
  static const double phoneInputHeight = 52;
  static const double otpBoxHeight = 56;
}
