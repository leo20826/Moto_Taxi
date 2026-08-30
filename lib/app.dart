import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'presentation/screens/home_screen.dart';

class MotoTaxiApp extends StatelessWidget {
  const MotoTaxiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moto Taxi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppTheme.darkBackground,
        primaryColor: AppTheme.primaryYellow,
        colorScheme: ColorScheme.dark(
          primary: AppTheme.primaryYellow,
          secondary: AppTheme.primaryYellow,
          surface: AppTheme.surfaceGrey,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppTheme.surfaceGrey,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryYellow,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
