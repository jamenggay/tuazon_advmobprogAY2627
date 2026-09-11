import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // reads the saved user data
  final UserService _userService = UserService();

  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // loads the saved user right 
    _loadUser();
  }

  // gets the saved user and turns it into a user model
  Future<void> _loadUser() async {
    setState(() {
      _isLoading = true;
    });

    final user = await _userService.getUser();
    if (!mounted) return;
    setState(() {
      _user = user;
      _isLoading = false;
    });
  }

    // logout function 
  Future<void> _logout() async {
    await _userService.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/signin');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final user = _user;

    if (user == null) {
      return Center(
        child: CustomText(
          text: 'No user data found',
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
        ),
      );
    }

//structure of the profile screen
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(user, theme, isDark),
          SizedBox(height: 8.h),
          CustomText(
            text: user.displayName,
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          CustomText(
            text: '@${user.username}',
            fontSize: 13.sp,
            textAlign: TextAlign.center,
            color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
          ),
          SizedBox(height: 24.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Account Information', isDark),
                SizedBox(height: 8.h),
                _buildDetailCard(
                  theme: theme,
                  isDark: isDark,
                  children: [
                    _buildDetailTile(
                      icon: Icons.person,
                      label: 'First name',
                      value: user.firstName,
                      theme: theme,
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildDetailTile(
                      icon: Icons.person_outline,
                      label: 'Last name',
                      value: user.lastName,
                      theme: theme,
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildDetailTile(
                      icon: Icons.tag,
                      label: 'Username',
                      value: user.username,
                      theme: theme,
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildDetailTile(
                      icon: Icons.alternate_email,
                      label: 'Email',
                      value: user.email,
                      theme: theme,
                      isDark: isDark,
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: Icon(
                      Icons.logout,
                      size: 20.sp,
                      color: theme.colorScheme.error,
                    ),
                    label: CustomText(
                      text: 'Log out',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.error,
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.colorScheme.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

 //header, contains the gradient banner and profile picture
  Widget _buildHeader(User user, ThemeData theme, bool isDark) {
    return SizedBox(
      
      height: 66.h + 104.r,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [AppColors.tealDeep, AppColors.darkCard]
                      : [AppColors.teal, AppColors.tealLight],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24.r),
                  bottomRight: Radius.circular(24.r),
                ),
              ),
            ),
          ),
          Positioned(
            top: 66.h,
            child: Container(
              padding: EdgeInsets.all(4.r),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 48.r,
                backgroundColor:
                    isDark ? AppColors.darkCard : AppColors.lightCard,
                backgroundImage:
                    user.image.isNotEmpty ? NetworkImage(user.image) : null,
                child: user.image.isEmpty
                    ? Icon(
                        Icons.person,
                        size: 48.sp,
                        color: isDark
                            ? AppColors.darkMuted
                            : AppColors.lightMuted,
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return CustomText(
      text: title.toUpperCase(),
      fontSize: 11.sp,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.0,
      color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
    );
  }

  Widget _buildDetailCard({
    required ThemeData theme,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        child: Column(children: children),
      ),
    );
  }

//for labels
  Widget _buildDetailTile({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.h,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              icon,
              size: 18.sp,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: label,
                  fontSize: 11.sp,
                  color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                ),
                SizedBox(height: 2.h),
                CustomText(
                  text: value.isEmpty ? '-' : value,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // row divider
  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
    );
  }
}
