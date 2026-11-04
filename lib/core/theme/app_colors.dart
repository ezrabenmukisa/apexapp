import 'package:material_ui/material_ui.dart';

/// Apex "field ledger" palette (docs: 01 Foundations).
///
/// Primary actions are [ink], not [laterite]. The brand colour is reserved
/// for the mark, focus rings and the one figure on a screen that matters most.
abstract final class AppColors {
  // Ground
  static const paper = Color(0xFFF6F2EA); // app ground
  static const surface = Color(0xFFFFFDF8); // cards, sheets
  static const sunk = Color(0xFFEEE7DA); // wells, tracks, read-only fields
  static const rule = Color(0xFFE0D6C6); // borders, dividers
  static const controlBorder = Color(0xFFCFC3B0); // inputs
  static const placeholder = Color(0xFFD9CFBF); // photo placeholders

  // Ink
  static const ink = Color(0xFF1F1B16); // text, primary actions
  static const ink2 = Color(0xFF4F473E); // body
  static const ink3 = Color(0xFF6E6357); // meta

  // Brand
  static const laterite = Color(0xFFA4441F); // brand, focus
  static const lateriteDeep = Color(0xFF7A2F14); // pressed
  static const lateriteTint = Color(0xFFF2DFD3); // highlight, focus ring

  // Status (foreground / background)
  static const approved = Color(0xFF2B5A4A);
  static const approvedBg = Color(0xFFDCEAE2);
  static const awaiting = Color(0xFF234E78);
  static const awaitingBg = Color(0xFFDCE5EF);
  static const changes = Color(0xFF7E4E00);
  static const changesBg = Color(0xFFF5E6C4);
  static const flagged = Color(0xFF9A2617);
  static const flaggedBg = Color(0xFFF5D9D2);
  static const notStarted = Color(0xFF5E554B);
  static const notStartedBg = Color(0xFFECE6DB);
}
