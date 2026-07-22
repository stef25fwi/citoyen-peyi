import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'citizen_design_tokens.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    const overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: CitizenDesignTokens.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemStatusBarContrastEnforced: false,
    );

    final scheme = ColorScheme.fromSeed(
      seedColor: CitizenDesignTokens.primaryBlue,
      brightness: Brightness.light,
      primary: CitizenDesignTokens.primaryBlue,
      onPrimary: CitizenDesignTokens.white,
      secondary: CitizenDesignTokens.yellowStrong,
      onSecondary: CitizenDesignTokens.navy,
      tertiary: CitizenDesignTokens.success,
      error: CitizenDesignTokens.error,
      surface: CitizenDesignTokens.surface,
      onSurface: CitizenDesignTokens.textDark,
    );

    final base = Typography.material2021(
      platform: defaultTargetPlatform,
    ).black;
    final textTheme = base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 54,
        fontWeight: FontWeight.w900,
        height: 1.03,
        letterSpacing: -1.8,
        color: CitizenDesignTokens.textDark,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 42,
        fontWeight: FontWeight.w900,
        height: 1.06,
        letterSpacing: -1.25,
        color: CitizenDesignTokens.textDark,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 34,
        fontWeight: FontWeight.w900,
        height: 1.1,
        letterSpacing: -0.8,
        color: CitizenDesignTokens.textDark,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 1.12,
        letterSpacing: -0.55,
        color: CitizenDesignTokens.textDark,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 23,
        fontWeight: FontWeight.w800,
        height: 1.16,
        letterSpacing: -0.35,
        color: CitizenDesignTokens.textDark,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        height: 1.18,
        letterSpacing: -0.25,
        color: CitizenDesignTokens.textDark,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: CitizenDesignTokens.textDark,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: CitizenDesignTokens.textDark,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        height: 1.52,
        color: CitizenDesignTokens.textDark,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.48,
        color: CitizenDesignTokens.textDark,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12,
        height: 1.42,
        color: CitizenDesignTokens.textMuted,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.1,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );

    final overlay = WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.pressed)) {
        return CitizenDesignTokens.deepBlue.withValues(alpha: 0.12);
      }
      if (states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused)) {
        return CitizenDesignTokens.primaryBlue.withValues(alpha: 0.08);
      }
      return null;
    });

    final roundedButton = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(CitizenDesignTokens.radiusButton),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: CitizenDesignTokens.background,
      canvasColor: CitizenDesignTokens.background,
      cardColor: CitizenDesignTokens.surface,
      dividerColor: CitizenDesignTokens.divider,
      disabledColor: CitizenDesignTokens.textSubtle.withValues(alpha: 0.55),
      splashFactory: InkRipple.splashFactory,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: CitizenDesignTokens.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: CitizenDesignTokens.textDark,
        centerTitle: false,
        systemOverlayStyle: overlayStyle,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 18),
        iconTheme: const IconThemeData(color: CitizenDesignTokens.textDark),
        actionsIconTheme:
            const IconThemeData(color: CitizenDesignTokens.textDark),
        shape: const Border(
          bottom: BorderSide(color: CitizenDesignTokens.divider),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: CitizenDesignTokens.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x16004D7A),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(CitizenDesignTokens.radiusCard),
          side: const BorderSide(color: CitizenDesignTokens.cardBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: CitizenDesignTokens.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x28002F4A),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(CitizenDesignTokens.radiusLarge),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 0,
        modalElevation: 0,
        backgroundColor: CitizenDesignTokens.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: Color(0x610B2F4A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(CitizenDesignTokens.radiusLarge),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CitizenDesignTokens.surfaceMuted,
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: CitizenDesignTokens.textMuted,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: CitizenDesignTokens.textSubtle,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(
          color: CitizenDesignTokens.error,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(CitizenDesignTokens.radiusField),
          borderSide: const BorderSide(color: CitizenDesignTokens.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(CitizenDesignTokens.radiusField),
          borderSide: const BorderSide(color: CitizenDesignTokens.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(CitizenDesignTokens.radiusField),
          borderSide: const BorderSide(
            color: CitizenDesignTokens.primaryBlue,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(CitizenDesignTokens.radiusField),
          borderSide: const BorderSide(color: CitizenDesignTokens.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(CitizenDesignTokens.radiusField),
          borderSide: const BorderSide(
            color: CitizenDesignTokens.error,
            width: 1.8,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(CitizenDesignTokens.radiusField),
          borderSide: const BorderSide(color: CitizenDesignTokens.divider),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        helperStyle: textTheme.bodySmall,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: CitizenDesignTokens.surfaceMuted,
        selectedColor: CitizenDesignTokens.skyBlue,
        disabledColor: CitizenDesignTokens.backgroundStrong,
        side: const BorderSide(color: CitizenDesignTokens.cardBorder),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(CitizenDesignTokens.radiusPill),
        ),
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: CitizenDesignTokens.deepBlue,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          elevation: const WidgetStatePropertyAll(0),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
          shape: WidgetStatePropertyAll(roundedButton),
          overlayColor: overlay,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor:
              const WidgetStatePropertyAll(CitizenDesignTokens.primaryBlue),
          foregroundColor:
              const WidgetStatePropertyAll(CitizenDesignTokens.white),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
          shape: WidgetStatePropertyAll(roundedButton),
          overlayColor: overlay,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          foregroundColor:
              const WidgetStatePropertyAll(CitizenDesignTokens.deepBlue),
          side: const WidgetStatePropertyAll(
            BorderSide(color: CitizenDesignTokens.cardBorder, width: 1.2),
          ),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
          shape: WidgetStatePropertyAll(roundedButton),
          overlayColor: overlay,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor:
              const WidgetStatePropertyAll(CitizenDesignTokens.deepBlue),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(CitizenDesignTokens.radiusSmall),
            ),
          ),
          overlayColor: overlay,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor:
              const WidgetStatePropertyAll(CitizenDesignTokens.textDark),
          overlayColor: overlay,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 2,
        highlightElevation: 0,
        backgroundColor: CitizenDesignTokens.primaryBlue,
        foregroundColor: CitizenDesignTokens.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(CitizenDesignTokens.radiusButton),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        elevation: 0,
        backgroundColor: CitizenDesignTokens.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: CitizenDesignTokens.skyBlue,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            color: selected
                ? CitizenDesignTokens.deepBlue
                : CitizenDesignTokens.textMuted,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? CitizenDesignTokens.deepBlue
                : CitizenDesignTokens.textMuted,
          );
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: CitizenDesignTokens.surface,
        selectedItemColor: CitizenDesignTokens.deepBlue,
        unselectedItemColor: CitizenDesignTokens.textMuted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      navigationRailTheme: NavigationRailThemeData(
        elevation: 0,
        backgroundColor: CitizenDesignTokens.surface,
        indicatorColor: CitizenDesignTokens.skyBlue,
        selectedIconTheme:
            const IconThemeData(color: CitizenDesignTokens.deepBlue),
        unselectedIconTheme:
            const IconThemeData(color: CitizenDesignTokens.textMuted),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: CitizenDesignTokens.deepBlue,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: CitizenDesignTokens.textMuted,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: CitizenDesignTokens.divider,
        indicatorColor: CitizenDesignTokens.primaryBlue,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: CitizenDesignTokens.deepBlue,
        unselectedLabelColor: CitizenDesignTokens.textMuted,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        overlayColor: overlay,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: CitizenDesignTokens.primaryBlue,
        textColor: CitizenDesignTokens.textDark,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodySmall,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(CitizenDesignTokens.radiusSmall),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: CitizenDesignTokens.navy,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: CitizenDesignTokens.white,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: CitizenDesignTokens.yellow,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(CitizenDesignTokens.radiusSmall),
        ),
        insetPadding: const EdgeInsets.all(16),
      ),
      popupMenuTheme: PopupMenuThemeData(
        elevation: 0,
        color: CitizenDesignTokens.surface,
        surfaceTintColor: Colors.transparent,
        textStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(CitizenDesignTokens.radiusButton),
          side: const BorderSide(color: CitizenDesignTokens.cardBorder),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: CitizenDesignTokens.navy,
          borderRadius:
              BorderRadius.circular(CitizenDesignTokens.radiusSmall),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: CitizenDesignTokens.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: CitizenDesignTokens.divider,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: CitizenDesignTokens.primaryBlue,
        linearTrackColor: CitizenDesignTokens.backgroundStrong,
        circularTrackColor: CitizenDesignTokens.backgroundStrong,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        side: const BorderSide(color: CitizenDesignTokens.textMuted),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return CitizenDesignTokens.primaryBlue;
          }
          return CitizenDesignTokens.surface;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? CitizenDesignTokens.primaryBlue
              : CitizenDesignTokens.textMuted;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? CitizenDesignTokens.white
              : CitizenDesignTokens.textSubtle;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? CitizenDesignTokens.primaryBlue
              : CitizenDesignTokens.backgroundStrong;
        }),
      ),
      badgeTheme: const BadgeThemeData(
        backgroundColor: CitizenDesignTokens.error,
        textColor: CitizenDesignTokens.white,
        smallSize: 8,
        largeSize: 18,
      ),
    );
  }
}