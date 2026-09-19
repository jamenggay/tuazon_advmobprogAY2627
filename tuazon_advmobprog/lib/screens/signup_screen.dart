import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // checks every field at once.
  final _formKey = GlobalKey<FormState>();

//fields in dummyjson.com/users.
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactNoController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // sign up uses the firebase 
  final _userService = UserService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    // clean up the text fields
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _contactNoController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // creates the firebase account 
  Future<void> _signUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      await _userService.createAccount(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        username: _usernameController.text.trim(),
        age: int.tryParse(_ageController.text.trim()) ?? 0,
        contactNo: _contactNoController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: CustomText(
            text: 'Account created.',
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

      // firebase already signs the new user in, so show the splash first
      // then it moves to the home page, same as signing in.
      // removing the screens behind it stops back from returning to the
      // sign up form.
      Navigator.pushNamedAndRemoveUntil(context, '/splash', (route) => false);
    } catch (e) {
      debugPrint('SIGN UP FAILED: $e');
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: CustomText(
          text: 'Create account',
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: theme.appBarTheme.foregroundColor ?? Colors.white,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomText(
                text: 'Fill in your details',
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                textAlign: TextAlign.left,
                color: isDark ? AppColors.sand : AppColors.tealDeep,
              ),
              SizedBox(height: 16.h),
              Card(
                elevation: 0,
                color: theme.cardTheme.color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20.r),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // first name
                        TextFormField(
                          controller: _firstNameController,
                          textInputAction: TextInputAction.next,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14.sp,
                          ),
                          decoration: _buildFieldDecoration(
                            label: 'First name',
                            icon: Icons.person,
                            theme: theme,
                            isDark: isDark,
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Enter your first name'
                                  : null,
                        ),
                        SizedBox(height: 16.h),
                        // last name
                        TextFormField(
                          controller: _lastNameController,
                          textInputAction: TextInputAction.next,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14.sp,
                          ),
                          decoration: _buildFieldDecoration(
                            label: 'Last name',
                            icon: Icons.person_outline,
                            theme: theme,
                            isDark: isDark,
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Enter your last name'
                                  : null,
                        ),
                        SizedBox(height: 16.h),
                        // age and username share one row to keep the form short.
                        Row(
                          // start keeps both boxes lined up when one shows an error.
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // age, numbers only
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _ageController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14.sp,
                                ),
                                decoration: _buildFieldDecoration(
                                  label: 'Age',
                                  icon: Icons.cake_outlined,
                                  theme: theme,
                                  isDark: isDark,
                                ),
                                validator: _validateAge,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            // username, given more space than age
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _usernameController,
                                textInputAction: TextInputAction.next,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14.sp,
                                ),
                                decoration: _buildFieldDecoration(
                                  label: 'Username',
                                  icon: Icons.tag,
                                  theme: theme,
                                  isDark: isDark,
                                ),
                                validator: (value) =>
                                    value == null || value.trim().length < 3
                                        ? 'Username must be at least 3 characters'
                                        : null,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        // contact number
                        TextFormField(
                          controller: _contactNoController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            // blocks letters, symbols like + ( ) - are fine.
                            FilteringTextInputFormatter.deny(
                              RegExp(r'[a-zA-Z]'),
                            ),
                          ],
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14.sp,
                          ),
                          decoration: _buildFieldDecoration(
                            label: 'Contact number',
                            icon: Icons.phone_outlined,
                            theme: theme,
                            isDark: isDark,
                          ),
                          validator: _validateContactNo,
                        ),
                        SizedBox(height: 16.h),
                        // email address
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14.sp,
                          ),
                          decoration: _buildFieldDecoration(
                            label: 'Email address',
                            icon: Icons.alternate_email,
                            theme: theme,
                            isDark: isDark,
                          ),
                          validator: _validateEmail,
                        ),
                        SizedBox(height: 16.h),
                        // password with its own rules
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
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
                          validator: _validatePassword,
                        ),
                        SizedBox(height: 16.h),
                        // confirm password
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          onFieldSubmitted: (_) => _signUp(),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14.sp,
                          ),
                          decoration: _buildFieldDecoration(
                            label: 'Confirm password',
                            icon: Icons.lock_reset,
                            theme: theme,
                            isDark: isDark,
                            suffix: IconButton(
                              tooltip: _obscureConfirm
                                  ? 'Show password'
                                  : 'Hide password',
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                size: 20.sp,
                                color: isDark
                                    ? AppColors.darkMuted
                                    : AppColors.lightMuted,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                            ),
                          ),
                          validator: (value) =>
                              value != _passwordController.text
                                  ? 'Passwords do not match'
                                  : null,
                        ),
                        SizedBox(height: 24.h),
                        SizedBox(
                          height: 40.h,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signUp,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: CustomText(
                              text: 'Sign up',
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
                    text: 'Already have an account? ',
                    fontSize: 15.sp,
                    color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                  ),
                  GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () =>
                            Navigator.pushReplacementNamed(context, '/signin'),
                    child: CustomText(
                      text: 'Sign In',
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
    );
  }

  // age must be a real number 
  String? _validateAge(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter your age';
    final age = int.tryParse(value.trim());
    if (age == null) return 'Age must be a number';
    if (age < 13 || age > 120) return 'Age must be between 13 and 120';
    return null;
  }

  // contact number rules
  String? _validateContactNo(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your contact number';
    }
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10 || digits.length > 13) {
      return 'Enter a valid contact number';
    }
    return null;
  }

  // email rules
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your email address';
    }
    final pattern = RegExp(r'^[\w.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
    if (!pattern.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  // password rules
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter your password';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Add at least one capital letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Add at least one small letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) return 'Add at least one number';
    return null;
  }

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
