import 'package:flutter/material.dart';

class StyleConstants {
  // ── Glassmorphism Tokens ──────────────────────────────────────────
  static const double glassBlur = 12.0;
  static const double glassOpacity = 0.15;
  static const double glassBorderOpacity = 0.1;
  static const double borderRadius = 16.0;

  // ── Color Schemes ──────────────────────────────────────────────────

  // Dark Theme (Modern Blue/Gold)
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkAccent = Color(0xFFD4AF37); // Gold
  static const Color darkText = Colors.white;
  static const Color darkGlass = Color(0x3364B5F6);

  // Light Theme (Clean Blue/Gold)
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Colors.white;
  static const Color lightAccent = Color(0xFF1B4F72); // Navy Blue
  static const Color lightText = Color(0xFF1E293B);
  static const Color lightGlass = Color(0x1A000000);

  // ── Theme Data ─────────────────────────────────────────────────────

  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF1B4F72),
      scaffoldBackgroundColor: lightBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1B4F72),
        brightness: Brightness.light,
        surface: lightSurface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1B4F72),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }

  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: darkAccent,
      scaffoldBackgroundColor: darkBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: darkAccent,
        brightness: Brightness.dark,
        surface: darkSurface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}

// ── Glass Container Widget ──────────────────────────────────────────
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final double opacity;
  final double? borderRadius;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.blur = StyleConstants.glassBlur,
    this.opacity = StyleConstants.glassOpacity,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = borderRadius ?? StyleConstants.borderRadius;

    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: Container(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color:
              (isDark
                      ? StyleConstants.darkSurface
                      : StyleConstants.lightSurface)
                  .withOpacity(
                    opacity * 2,
                  ), // Increase opacity for better contrast without blur
          borderRadius: BorderRadius.circular(r),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withOpacity(
              StyleConstants.glassBorderOpacity,
            ),
            width: 1,
          ),
        ),
        child: child,
      ),
    );
  }
}
