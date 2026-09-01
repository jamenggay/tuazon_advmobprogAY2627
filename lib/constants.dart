import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final String host = dotenv.env['HOST'] ??
    dotenv.env['BASE_URL'] ??
    'https://dummyjson.com';


/// App color palette.
class AppColors {
  AppColors._();

  // Main brand colors.
  static const Color teal = Color(0xFF007979); 
  static const Color tealLight = Color(0xFF24B1B1); 
  static const Color sand = Color(0xFFFFE2AF); 
  static const Color ember = Color(0xFFE37434); 

  // Darker brand colors.
  static const Color tealDeep = Color(0xFF005757); 
  static const Color sandDeep = Color(0xFFF5C97A); 
  static const Color emberDeep = Color(0xFFB4551F); 

  // Light theme colors.
  static const Color lightBackground = Color(0xFFF2F8F8);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFCFE5E5);
  static const Color lightSkeleton = Color(0xFFE4F0F0);

  // Dark theme colors.
  static const Color darkBackground = Color(0xFF042B2B);
  static const Color darkCard = Color(0xFF0A3D3D);
  static const Color darkBorder = Color(0xFF14595A);
  static const Color darkSkeleton = Color(0xFF14595A);

  // Muted icon colors.
  static const Color lightMuted = Color(0xFF6E8F8F);
  static const Color darkMuted = Color(0xFF7FA8A8);

  // Status colors.
  static const Color error = Color(0xFFD1462F);
  static const Color errorLight = Color(0xFFF08A76);
  static const Color success = teal;
  static const Color warning = ember;
}
