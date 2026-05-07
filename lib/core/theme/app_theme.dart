import 'package:flutter/material.dart';

class AppTheme {
  // Paleta Vibrant Red & Clean
  static const Color offWhite = Color(0xFFFAFAFA);
  static const Color primaryRed = Color(0xFFE53935);
  static const Color softBlue = Color(0xFFE3F2FD);   
  static const Color darkGrey = Color(0xFF212121);
  static const Color mediumGrey = Color(0xFF757575);

  // Nuevos colores para el rediseño (Ajustados a ROJO por petición del usuario)
  static const Color vibrantRed = Color(0xFFFF1744); // Rojo vibrante para botones y FAB
  static const Color softRed = Color(0xFFEF9A9A); // Rojo Suave para botones
  static const Color ultraSoftRed = Color(0xFFFFEBEE); // Fondo muy suave
  static const Color softOrange = Color(0xFFFFB74D); // Amarillo Anaranjado
  static const Color pastelPink = Color(0xFFF8BBD0); // Rosa Pastel para iconos
  static const Color pastelGreen = Color(0xFFE8F5E9); // Verde Pastel suave para estado 'Tomado'
  static const Color lightGrey = Color(0xFFBDBDBD);   // Gris claro para texto 'Tomado'

  static const Color pastelRed = Color(0xFFFFCDD2);  // Rojo pastel discreto
  static const Color pastelYellow = Color(0xFFFFF9C4); // Amarillo Pastel




  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: offWhite,
      primaryColor: primaryRed,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryRed,
        surface: Colors.white,
        primary: primaryRed,
        secondary: softBlue,
        onSurface: darkGrey,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: darkGrey, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: darkGrey, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: darkGrey),
        bodyMedium: TextStyle(color: darkGrey),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: darkGrey),
        titleTextStyle: TextStyle(color: darkGrey, fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  static const BoxDecoration backgroundDecoration = BoxDecoration(
    color: offWhite,
  );

  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];
}
