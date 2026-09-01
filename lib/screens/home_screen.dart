import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'cart_screen.dart';
import 'product_screen.dart';
import 'profile_screen.dart';
import '../constants.dart';
import '../widgets/custom_text.dart';

class HomeScreen extends StatefulWidget {
  // Main screen with shop, cart, and profile tabs.
  final String username;

  const HomeScreen({super.key, this.username = ''});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  // cart page index saved in a variable.
  static const int _cartPageIndex = 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Read the current color theme settings
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onAppBar = theme.appBarTheme.foregroundColor ?? Colors.white;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          title: _selectedIndex == 0
              ? Image.asset(
                  'assets/images/nubdexchange_logo.png',
                  scale: 11.5.sp,
                )
              : CustomText(
                  text: _selectedIndex == _cartPageIndex ? 'Cart' : 'Profile',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: onAppBar,
                ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings, size: 24.sp, color: onAppBar),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
        body: PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: _pageController,
          children: const <Widget>[
            ProductScreen(),
            CartScreen(),
            ProfileScreen(),
          ],
          onPageChanged: (page) {
            setState(() {
              _selectedIndex = page;
            });
          },
        ),

        //chat icon navigation -> floating icon
        floatingActionButton: _selectedIndex == _cartPageIndex
            ? null
            : FloatingActionButton(
                backgroundColor: theme.colorScheme.primary,
                onPressed: _onChatPressed,
                tooltip: 'Chat',
                child: Icon(
                  Icons.chat,
                  size: 24.sp,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
        bottomNavigationBar: BottomNavigationBar(
          showSelectedLabels: true,
          showUnselectedLabels: false,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: isDark
              ? AppColors.darkMuted
              : AppColors.lightMuted,
          backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
          type: BottomNavigationBarType.fixed,
          onTap: _onTappedBar,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.shop_2), label: 'Shop'),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          currentIndex: _selectedIndex,
        ),
      ),
    );
  }

  // Placeholder action for the floating chat button.
  void _onChatPressed() {}

  // Switches the selected tab and updates the visible page.
  void _onTappedBar(int value) {
    setState(() {
      _selectedIndex = value;
    });

    _pageController.jumpToPage(value);
  }
}
