import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  // restrictions
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  // login API
  final _userService = UserService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isCheckingLogin = true;
  bool _useFirebase = false;

  @override
  void initState() {
    super.initState();
    // checks if the device already has a saved login
    _checkExistingLogin();
  }

  // maintains sign in state of user if hindi mag log out
  Future<void> _checkExistingLogin() async {
    bool isLoggedIn = false;
    try {
      isLoggedIn = await _userService.isLoggedIn();
    } catch (e) {
      debugPrint('TOKEN CHECK FAILED: $e');
      isLoggedIn = false;
    }

    if (!mounted) return;

    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/splash');
    } else {
      setState(() => _isCheckingLogin = false);
    }
  }

  @override
  void dispose() {
    // Clean up the text fields
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Sign in function
  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      if (_useFirebase) {
        // firebase auth uses the sdk and an email address.
        await _userService.signIn(
          email: _usernameController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // dummyjson uses the api call with a username.
        await _userService.loginUser(
          _usernameController.text.trim(),
          _passwordController.text.trim(),
        );
      }
      if (!mounted) return;
      //triggers splash screen
      Navigator.pushReplacementNamed(context, '/splash');
    } catch (e) {
      debugPrint('SIGN IN FAILED: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: CustomText(
            // shows a clear reason instead of the raw error.
            text: UserService.friendlyError(e),
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isCheckingLogin) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

//sign in screen
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/nubdexchange_logo.png',
                    width: 130.w,
                  ),
                ),
                SizedBox(height: 16.h),
                CustomText(
                  text: 'NU Online Shopping Center',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  textAlign: TextAlign.center,
                  color: isDark ? AppColors.sand : AppColors.tealDeep,
                ),
                SizedBox(height: 6.h),
                CustomText(
                  text: 'Sign in to continue shopping',
                  fontSize: 13.sp,
                  textAlign: TextAlign.center,
                  color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                ),
                SizedBox(height: 24.h),
                Card(
                  elevation: 0,
                  color: theme.cardTheme.color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    side: BorderSide(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20.r),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // lets the user pick which login to use.
                          _buildLoginTypePicker(theme, isDark),
                          SizedBox(height: 16.h),
                          TextFormField(
                            controller: _usernameController,
                            textInputAction: TextInputAction.next,
                            keyboardType: _useFirebase
                                ? TextInputType.emailAddress
                                : TextInputType.text,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14.sp,
                            ),
                            decoration: _buildFieldDecoration(
                              // firebase signs in with an email then dummyjson with a username.
                              label: _useFirebase ? 'Email address' : 'Username',
                              icon: _useFirebase
                                  ? Icons.alternate_email
                                  : Icons.person_outline,
                              theme: theme,
                              isDark: isDark,
                            ),
                            // shows a red message if the field is empty
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? _useFirebase
                                        ? 'Enter your email address'
                                        : 'Enter your username'
                                    : null,
                          ),
                          SizedBox(height: 16.h),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            onFieldSubmitted: (_) => _login(),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14.sp,
                            ),
                            decoration: _buildFieldDecoration(
                              label: 'Password',
                              icon: Icons.lock_outline,
                              theme: theme,
                              isDark: isDark,
                              suffix: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Show password'
                                    : 'Hide password',
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  size: 20.sp,
                                  color: isDark
                                      ? AppColors.darkMuted
                                      : AppColors.lightMuted,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Enter your password'
                                : null,
                          ),
                          SizedBox(height: 24.h),
                          SizedBox(
                            height: 40.h,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: CustomText(
                                text: 'Sign in',
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomText(
                      text: 'No account yet? ',
                      fontSize: 15.sp,
                      color:
                          isDark ? AppColors.darkMuted : AppColors.lightMuted,
                    ),
                    GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () => Navigator.pushNamed(context, '/signup'),
                      child: CustomText(
                        text: 'Sign Up',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        // underline shows that it can be tapped.
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // two buttons that switch between dummyjson and firebase.
  Widget _buildLoginTypePicker(ThemeData theme, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: CustomText(
              text: 'DummyJSON',
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              textAlign: TextAlign.center,
              color: !_useFirebase
                  ? theme.colorScheme.onPrimaryContainer
                  : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
            ),
            selected: !_useFirebase,
            selectedColor: theme.colorScheme.primaryContainer,
            onSelected: (_) => setState(() => _useFirebase = false),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: ChoiceChip(
            label: CustomText(
              text: 'Firebase',
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              textAlign: TextAlign.center,
              color: _useFirebase
                  ? theme.colorScheme.onPrimaryContainer
                  : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
            ),
            selected: _useFirebase,
            selectedColor: theme.colorScheme.primaryContainer,
            onSelected: (_) => setState(() => _useFirebase = true),
          ),
        ),
      ],
    );
  }

  //username and pass field
  InputDecoration _buildFieldDecoration({
    required String label,
    required IconData icon,
    required ThemeData theme,
    required bool isDark,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14.sp,
        color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
      ),
      prefixIcon: Icon(
        icon,
        size: 20.sp,
        color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
      ),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: theme.colorScheme.primary),
      ),
    );
  }
}
