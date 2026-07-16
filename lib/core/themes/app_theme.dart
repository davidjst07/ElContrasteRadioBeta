import 'package:flutter/material.dart';

class AppColors {
  static const navyDeep = Color(0xFF0B1B2B);
  static const navyCard = Color(0xFF0D2A4E);
  static const navyAppbar = Color(0xFF082742);
  static const navyOriginal = Color(0xFF0B375E);
  static const blueBrand = Color(0xFF2A86C7);
  static const blueTabSelected = Color(0xFF2A4C9C);
  static const blueText = Color(0xFF89CFF0);
  static const purplePlaceholder = Color(0xFF201868);
  static const navyText = Color(0xFF1A2B40);

  static const lightBackground = Color(0xFF0B375E);
  static const lightSurface = Color(0xFF114A7A);
  static const lightCard = Color(0xFF14508A);
  static const lightAppbar = Color(0xFF0A2E50);
}

class ElContrasteThemeExtension extends ThemeExtension<ElContrasteThemeExtension> {
  final Color cardColor;
  final Color tabBarSelected;
  final Color placeholderColor;
  final Color accentTextColor;

  const ElContrasteThemeExtension({
    required this.cardColor,
    required this.tabBarSelected,
    required this.placeholderColor,
    required this.accentTextColor,
  });

  static const dark = ElContrasteThemeExtension(
    cardColor: AppColors.navyCard,
    tabBarSelected: AppColors.blueTabSelected,
    placeholderColor: AppColors.purplePlaceholder,
    accentTextColor: AppColors.blueText,
  );

  static const light = ElContrasteThemeExtension(
    cardColor: AppColors.lightCard,
    tabBarSelected: AppColors.blueBrand,
    placeholderColor: Color(0xFF1A3A5C),
    accentTextColor: AppColors.blueText,
  );

  @override
  ElContrasteThemeExtension copyWith({
    Color? cardColor,
    Color? tabBarSelected,
    Color? placeholderColor,
    Color? accentTextColor,
  }) =>
      ElContrasteThemeExtension(
        cardColor: cardColor ?? this.cardColor,
        tabBarSelected: tabBarSelected ?? this.tabBarSelected,
        placeholderColor: placeholderColor ?? this.placeholderColor,
        accentTextColor: accentTextColor ?? this.accentTextColor,
      );

  @override
  ElContrasteThemeExtension lerp(
    ThemeExtension<ElContrasteThemeExtension>? other,
    double t,
  ) {
    if (other is! ElContrasteThemeExtension) return this;
    return ElContrasteThemeExtension(
      cardColor: Color.lerp(cardColor, other.cardColor, t)!,
      tabBarSelected: Color.lerp(tabBarSelected, other.tabBarSelected, t)!,
      placeholderColor: Color.lerp(placeholderColor, other.placeholderColor, t)!,
      accentTextColor: Color.lerp(accentTextColor, other.accentTextColor, t)!,
    );
  }
}

extension ElContrasteTheme on BuildContext {
  ElContrasteThemeExtension get themeColors =>
      Theme.of(this).extension<ElContrasteThemeExtension>()!;
}

class AppTheme {
  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        scaffoldBg: AppColors.navyDeep,
        surface: AppColors.navyCard,
        primary: const Color.fromARGB(255, 34, 109, 163),
        onPrimary: Colors.white,
        onSurface: Colors.white,
        onSurfaceVariant: Colors.white70,
        appBarBg: AppColors.navyAppbar,
        extension: ElContrasteThemeExtension.dark,
      );

  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        scaffoldBg: AppColors.lightBackground,
        surface: AppColors.lightSurface,
        primary: const Color.fromARGB(255, 32, 101, 151),
        onPrimary: Colors.white,
        onSurface: Colors.white,
        onSurfaceVariant: Colors.white70,
        appBarBg: AppColors.lightAppbar,
        extension: ElContrasteThemeExtension.light,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color scaffoldBg,
    required Color surface,
    required Color primary,
    required Color onPrimary,
    required Color onSurface,
    required Color onSurfaceVariant,
    required Color appBarBg,
    required ElContrasteThemeExtension extension,
  }) {
    final colorScheme = brightness == Brightness.dark
        ? ColorScheme.dark(
            primary: primary,
            onPrimary: onPrimary,
            surface: surface,
            onSurface: onSurface,
            surfaceContainer: surface,
          )
        : ColorScheme.light(
            primary: primary,
            onPrimary: onPrimary,
            surface: surface,
            onSurface: onSurface,
            surfaceContainer: surface,
          );

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBg,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: onPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: onPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: onSurface),
        bodyMedium: TextStyle(color: onSurface),
        bodySmall: TextStyle(color: onSurfaceVariant),
        titleLarge: TextStyle(color: onSurface),
      ),
      extensions: [extension],
    );
  }
}
