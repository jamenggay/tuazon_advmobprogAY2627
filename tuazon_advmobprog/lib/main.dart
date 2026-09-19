import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/splash_screen.dart';
import 'poviders/theme_provider.dart';
import 'firebase_options.dart';

void main() async {
  // Start the app with required device settings and environment setup.
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await dotenv.load(fileName: 'assets/.env');

  // Firebase must be ready before any FirebaseAuth call.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const TuazonAdvMobProg());
}

class TuazonAdvMobProg extends StatelessWidget {
  const TuazonAdvMobProg({super.key});

  @override
  Widget build(BuildContext context) {
    // app-wide theme and route setup 
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: ScreenUtilInit(
        designSize: const Size(412, 715),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (build, child) {
          final themeModel = build.watch<ThemeProvider>();

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themeModel.lightTheme,
            darkTheme: themeModel.darkTheme,
            themeMode: themeModel.isDark ? ThemeMode.dark : ThemeMode.light,
            title: 'NU Online Shopping Center',
            // start at sign-in to check the saved session.
            initialRoute: '/signin',
            routes: {
              '/home': (context) => const HomeScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/product-detail': (context) => const ProductDetailScreen(),
              '/signin': (context) => const SignInScreen(),
              '/splash': (context) => const SplashScreen(),
            },
          );
        },
      ),
    );
  }
}
