import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants.dart';
import '../widgets/custom_text.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Start the timer
    _goToHome();
  }

  //automatic timer for splash screen then proceed to homescreen
  Future<void> _goToHome() async {
    // Change the number here if you want a shorter or longer splash
    await Future<void>.delayed(const Duration(seconds: 5));

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

//splash screens tructure
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/nubdexchange_logo.png',
                width: 200.w,
              ),
              SizedBox(height: 24.h),
              CustomText(
                text: 'NU Online Shopping Center',
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                textAlign: TextAlign.center,
                color: isDark ? AppColors.sand : AppColors.tealDeep,
              ),
              SizedBox(height: 8.h),
              CustomText(
                text: 'Your campus online store',
                fontSize: 13.sp,
                textAlign: TextAlign.center,
                color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
