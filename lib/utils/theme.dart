import 'package:flutter/material.dart';

class AppTheme {
  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        surface: Colors.white,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],

        // Content padding for better spacing
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),

        // Border styling
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),

        // Label styling
        labelStyle: TextStyle(
          fontSize: 16,
          color: Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          fontSize: 16,
          color: Colors.blue,
          fontWeight: FontWeight.w600,
        ),

        // Hint text styling
        hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),

        // Icon theme
        prefixIconColor: Colors.grey[600],
        suffixIconColor: Colors.grey[600],

        // Error styling
        errorStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        errorMaxLines: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue, // Blue background
          foregroundColor: Colors.white, // White text
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 2,
          shadowColor: Colors.blue.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          // Disabled state
          disabledBackgroundColor: Colors.grey[300],
          disabledForegroundColor: Colors.grey[600],
        ),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
        primary: const Color(0xFF64B5F6), // Lighter blue for dark mode
        surface: const Color(0xFF1E1E1E), // Dark surface
        //background: const Color(0xFF121212), // Dark background
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Color(0xFF1E1E1E),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C), // Darker fill for inputs
        // Content padding for better spacing
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),

        // Border styling
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3E3E3E)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3E3E3E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF64B5F6), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF5350), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF5350), width: 2),
        ),

        // Label styling
        labelStyle: const TextStyle(
          fontSize: 16,
          color: Color(0xFFB0B0B0),
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          fontSize: 16,
          color: Color(0xFF64B5F6),
          fontWeight: FontWeight.w600,
        ),

        // Hint text styling
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF6E6E6E)),

        // Icon theme
        prefixIconColor: const Color(0xFF9E9E9E),
        suffixIconColor: const Color(0xFF9E9E9E),

        // Error styling
        errorStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFFEF5350),
        ),
        errorMaxLines: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(
            0xFF64B5F6,
          ), // Lighter blue for dark mode
          foregroundColor: const Color(0xFF121212), // Dark text on light button
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 2,
          shadowColor: const Color(0xFF64B5F6).withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          // Disabled state
          disabledBackgroundColor: const Color(0xFF3E3E3E),
          disabledForegroundColor: const Color(0xFF6E6E6E),
        ),
      ),
      // Tab bar theme for dark mode
      tabBarTheme: const TabBarThemeData(
        indicatorColor: Color(0xFF64B5F6),
        labelColor: Color(0xFF64B5F6),
        unselectedLabelColor: Color(0xFF9E9E9E),
      ),
      // Chip theme for dark mode
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2C2C2C),
        selectedColor: const Color(0xFF64B5F6).withValues(alpha: 0.3),
        labelStyle: const TextStyle(color: Color(0xFFE0E0E0)),
        side: const BorderSide(color: Color(0xFF3E3E3E)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      // Divider theme
      dividerTheme: const DividerThemeData(
        color: Color(0xFF3E3E3E),
        thickness: 1,
      ),
    );
  }
}
