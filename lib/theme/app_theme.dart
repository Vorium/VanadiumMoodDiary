import 'package:flutter/material.dart';
import 'app_tokens.dart';

/// Material 3 主题
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppTokens.primary,
      brightness: Brightness.light,
      primary: AppTokens.primary,
      onPrimary: Colors.white,
      surface: AppTokens.surface,
      onSurface: AppTokens.textPrimary,
      error: AppTokens.error,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppTokens.background,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      textTheme: _textTheme,
      appBarTheme: _appBarTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
      inputDecorationTheme: _inputDecorationTheme,
      cardTheme: _cardThemeData,
      dividerTheme: const DividerThemeData(
        color: AppTokens.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: AppTokens.fontSizeTitle,
      fontWeight: FontWeight.w600,
      color: AppTokens.textPrimary,
      height: AppTokens.lineHeightTight,
    ),
    displayMedium: TextStyle(
      fontSize: AppTokens.fontSizeHeadline,
      fontWeight: FontWeight.w600,
      color: AppTokens.textPrimary,
      height: AppTokens.lineHeightTight,
    ),
    bodyLarge: TextStyle(
      fontSize: AppTokens.fontSizeBody,
      fontWeight: FontWeight.w400,
      color: AppTokens.textPrimary,
      height: AppTokens.lineHeightNormal,
    ),
    bodyMedium: TextStyle(
      fontSize: AppTokens.fontSizeBody,
      fontWeight: FontWeight.w400,
      color: AppTokens.textSecondary,
      height: AppTokens.lineHeightNormal,
    ),
    labelLarge: TextStyle(
      fontSize: AppTokens.fontSizeButton,
      fontWeight: FontWeight.w500,
      color: AppTokens.textPrimary,
    ),
    labelMedium: TextStyle(
      fontSize: AppTokens.fontSizeLabel,
      fontWeight: FontWeight.w400,
      color: AppTokens.textSecondary,
    ),
  );

  static const AppBarTheme _appBarTheme = AppBarTheme(
    backgroundColor: AppTokens.background,
    foregroundColor: AppTokens.textPrimary,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontSize: AppTokens.fontSizeHeadline,
      fontWeight: FontWeight.w600,
      color: AppTokens.textPrimary,
    ),
  );

  static ElevatedButtonThemeData get _elevatedButtonTheme =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, AppTokens.buttonHeight),
          backgroundColor: AppTokens.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTokens.disabled,
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusButton),
          ),
          textStyle: const TextStyle(
            fontSize: AppTokens.fontSizeButton,
            fontWeight: FontWeight.w600,
            height: AppTokens.lineHeightTight,
          ),
          elevation: 0,
        ),
      );

  static OutlinedButtonThemeData get _outlinedButtonTheme =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, AppTokens.buttonHeightSmall),
          side: const BorderSide(color: AppTokens.primary, width: 1.5),
          foregroundColor: AppTokens.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusButton),
          ),
          textStyle: const TextStyle(
            fontSize: AppTokens.fontSizeButton,
            fontWeight: FontWeight.w500,
            height: AppTokens.lineHeightTight,
          ),
        ),
      );

  static TextButtonThemeData get _textButtonTheme => TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppTokens.primary,
          textStyle: const TextStyle(
            fontSize: AppTokens.fontSizeBody,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

  static InputDecorationTheme get _inputDecorationTheme =>
      InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacingMd,
          vertical: AppTokens.spacingMd,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusInput),
          borderSide: const BorderSide(color: AppTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusInput),
          borderSide: const BorderSide(color: AppTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusInput),
          borderSide: const BorderSide(color: AppTokens.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusInput),
          borderSide: const BorderSide(color: AppTokens.error),
        ),
        labelStyle: const TextStyle(
          fontSize: AppTokens.fontSizeLabel,
          color: AppTokens.textSecondary,
        ),
        hintStyle: const TextStyle(
          fontSize: AppTokens.fontSizeBody,
          color: AppTokens.textHint,
        ),
      );

  static CardThemeData get _cardThemeData => CardThemeData(
        color: AppTokens.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          side: const BorderSide(color: AppTokens.divider),
        ),
      );
}
