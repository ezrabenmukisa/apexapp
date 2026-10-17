import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'app_dimensions.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get light {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.ink,
      onPrimary: AppColors.paper,
      secondary: AppColors.laterite,
      onSecondary: AppColors.surface,
      error: AppColors.flagged,
      onError: AppColors.surface,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.ink2,
      surfaceContainerHighest: AppColors.sunk,
      outline: AppColors.controlBorder,
      outlineVariant: AppColors.rule,
    );

    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusControl),
    );

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusControl),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.paper,
      fontFamily: AppTextStyles.ui,
      dividerTheme: const DividerThemeData(
        color: AppColors.rule,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.title,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.paper,
          disabledBackgroundColor: AppColors.rule,
          disabledForegroundColor: AppColors.ink3,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
          shape: controlShape,
          textStyle: AppTextStyles.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(
            AppDimensions.secondaryButtonHeight,
          ),
          side: const BorderSide(color: AppColors.ink, width: 1.5),
          shape: controlShape,
          textStyle: AppTextStyles.buttonSecondary,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size(0, 40),
          textStyle: AppTextStyles.label,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.ink3),
        border: border(AppColors.controlBorder),
        enabledBorder: border(AppColors.controlBorder),
        disabledBorder: border(AppColors.controlBorder),
        focusedBorder: border(AppColors.ink, 1.5),
        errorBorder: border(AppColors.flagged),
        focusedErrorBorder: border(AppColors.flagged, 1.5),
        errorStyle: AppTextStyles.small.copyWith(color: AppColors.flagged),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: AppTextStyles.body.copyWith(color: AppColors.paper),
        behavior: SnackBarBehavior.floating,
        shape: controlShape,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusCard),
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.ink,
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.all(AppColors.ink),
      ),
    );
  }
}
