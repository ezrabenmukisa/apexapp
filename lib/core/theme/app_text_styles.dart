import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Type roles (docs: 01 Foundations).
///
/// - Newsreader: screen titles, project names and money.
/// - Hanken Grotesk: interface — labels, body, buttons.
/// - IBM Plex Mono: proof data — coordinates, timestamps, receipt numbers.
abstract final class AppTextStyles {
  static TextStyle _display(double size, double height) =>
      GoogleFonts.newsreader(
        fontSize: size,
        height: height / size,
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
      );

  static TextStyle _ui(double size, double height, FontWeight weight) =>
      GoogleFonts.hankenGrotesk(
        fontSize: size,
        height: height / size,
        fontWeight: weight,
        color: AppColors.ink,
      );

  static TextStyle mono({
    double size = 12,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.ink,
    double letterSpacing = 0.06,
  }) => GoogleFonts.ibmPlexMono(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: size * letterSpacing,
  );

  // Display — Newsreader
  static final displayXl = _display(40, 44);
  static final hero = _display(38, 42).copyWith(letterSpacing: -0.57);
  static final displayL = _display(32, 36);
  static final displayM = _display(28, 34);
  static final brand = _display(24, 28);

  // Interface — Hanken Grotesk
  static final title = _ui(20, 26, FontWeight.w600);
  static final bodyLarge = _ui(16, 24, FontWeight.w400);
  static final body = _ui(15, 22, FontWeight.w400);
  static final label = _ui(14, 20, FontWeight.w600);
  static final button = _ui(16, 20, FontWeight.w700);
  static final buttonSecondary = _ui(16, 20, FontWeight.w600);
  static final caption = _ui(13, 18, FontWeight.w400);
  static final small = _ui(12, 17, FontWeight.w400);

  // Proof — IBM Plex Mono
  static final proof = mono();
  static final stepLabel = mono(color: AppColors.ink3);
}
