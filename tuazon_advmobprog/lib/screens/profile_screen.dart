import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/app_dialog.dart';
import '../widgets/custom_text.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();

  User? _user;
  bool _isLoading = true;
  // stores if the user came from dummyjson or firebase.
  String _loginType = '';

 
  final _usernameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // loads the saved user right
    _loadUser();
  }

  @override
  void dispose() {
    // clean up the dialog text fields when the screen is closed
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  // gets the saved user and turns it into a user model
  Future<void> _loadUser() async {
    setState(() {
      _isLoading = true;
    });

    //  holds the login type
    final userData = await _userService.getUserData();
    final user = User.fromJson(userData);

    if (!mounted) return;
    setState(() {
      _user = user;
      _loginType = user.loginType;
      _isLoading = false;
    });
  }

    // logout function
  Future<void> _logout() async {
    // ask first so the user does not log out by accident.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => buildAppDialog(
        dialogContext: dialogContext,
        title: 'Log out',
        message: 'Are you sure you want to log out?',
        confirmLabel: 'Log out',
        isDanger: true,
        // just a confirm, no boxes to fill up.
        fields: const [],
        onConfirm: () => Navigator.pop(dialogContext, true),
      ),
    );

    if (confirmed != true) return;

    await _userService.logout();
    if (!mounted) return;
    // removes every screen behind it so back cannot return to the app.
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
  }

  // snackbar/toast
  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: CustomText(
          text: message,
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // change username popup modal
  Future<void> _updateUsername() async {
    _usernameController.text = _user?.username ?? '';

    final newUsername = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final isDark = theme.brightness == Brightness.dark;

        return buildAppDialog(
          dialogContext: dialogContext,
          title: 'Update username',
          message: 'This is the name shown on your profile.',
          confirmLabel: 'Save',
          fields: [
            buildDialogField(
              controller: _usernameController,
              label: 'New username',
              icon: Icons.tag,
              theme: theme,
              isDark: isDark,
            ),
          ],
          onConfirm: () =>
              Navigator.pop(dialogContext, _usernameController.text.trim()),
        );
      },
    );

    if (newUsername == null || newUsername.isEmpty) return;

    try {
      await _userService.updateUsername(username: newUsername);
      await _loadUser();
      _showMessage('Username updated.');
    } catch (e) {
      debugPrint('UPDATE USERNAME FAILED: $e');
      _showMessage(UserService.friendlyError(e));
    }
  }

  // change pass popup modal
  Future<void> _changePassword() async {
    _currentPasswordController.clear();
    _newPasswordController.clear();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final isDark = theme.brightness == Brightness.dark;

        return buildAppDialog(
          dialogContext: dialogContext,
          title: 'Change password',
          message: 'Your new password needs at least 8 characters.',
          confirmLabel: 'Save',
          fields: [
            buildDialogField(
              controller: _currentPasswordController,
              label: 'Current password',
              icon: Icons.lock_outline,
              theme: theme,
              isDark: isDark,
              obscure: true,
            ),
            SizedBox(height: 16.h),
            buildDialogField(
              controller: _newPasswordController,
              label: 'New password',
              icon: Icons.lock_reset,
              theme: theme,
              isDark: isDark,
              obscure: true,
            ),
          ],
          onConfirm: () => Navigator.pop(dialogContext, true),
        );
      },
    );

    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    if (confirmed != true) return;

    if (newPassword.length < 8) {
      _showMessage('New password must be at least 8 characters.');
      return;
    }

    try {
      await _userService.resetPasswordFromCurrentPassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        email: _user?.email ?? '',
      );
      _showMessage('Password changed.');
    } catch (e) {
      debugPrint('CHANGE PASSWORD FAILED: $e');
      _showMessage(UserService.friendlyError(e));
    }
  }

//delete account popup modal
  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => buildAppDialog(
        dialogContext: dialogContext,
        title: 'Delete account',
        message: 'This cannot be undone. Your account will be removed.',
        confirmLabel: 'Delete',
        // red popup because this one removes the account.
        isDanger: true,
        // just a confirm, no password needed.
        fields: const [],
        onConfirm: () => Navigator.pop(dialogContext, true),
      ),
    );

    if (confirmed != true) return;

    try {
      await _userService.deleteAccount();
      if (!mounted) return;
      // the account is gone so go back to the sign in screen.
      Navigator.pushReplacementNamed(context, '/signin');
    } catch (e) {
      debugPrint('DELETE ACCOUNT FAILED: $e');
      _showMessage(UserService.friendlyError(e));
    }
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

    // the account actions only work on firebase accounts.
    final isFirebase = _loginType == UserService.loginTypeFirebase;

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
          SizedBox(height: 8.h),
          // small label showing where the user signed in from.
          _buildLoginTypeBadge(theme, isFirebase),
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
                  // the rows shown depend on the login type.
                  children: isFirebase
                      ? _buildFirebaseDetails(user, theme, isDark)
                      : _buildDummyJsonDetails(user, theme, isDark),
                ),
                SizedBox(height: 24.h),
                _buildSectionTitle('Account Actions', isDark),
                SizedBox(height: 8.h),
                // dummyjson accounts cannot be edited from the app.
                if (!isFirebase)
                  Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: CustomText(
                      text:
                          'Account actions are only available for Firebase accounts.',
                      fontSize: 12.sp,
                      color:
                          isDark ? AppColors.darkMuted : AppColors.lightMuted,
                    ),
                  ),
                _buildActionButton(
                  label: 'Update username',
                  icon: Icons.edit,
                  theme: theme,
                  onPressed: isFirebase ? _updateUsername : null,
                ),
                SizedBox(height: 8.h),
                _buildActionButton(
                  label: 'Change password',
                  icon: Icons.lock_reset,
                  theme: theme,
                  onPressed: isFirebase ? _changePassword : null,
                ),
                SizedBox(height: 8.h),
                _buildActionButton(
                  label: 'Delete account',
                  icon: Icons.delete_outline,
                  theme: theme,
                  isDanger: true,
                  onPressed: isFirebase ? _deleteAccount : null,
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  height: 38.h,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: Icon(
                      Icons.logout,
                      size: 16.sp,
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
                      // smaller padding so the button is not too tall.
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
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

  // rows shown for a dummyjson account.
  List<Widget> _buildDummyJsonDetails(User user, ThemeData theme, bool isDark) {
    return [
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
      _buildDivider(isDark),
      _buildDetailTile(
        icon: Icons.wc,
        label: 'Gender',
        value: user.gender,
        theme: theme,
        isDark: isDark,
      ),
    ];
  }

  // rows shown for a firebase account, includes the sign up fields.
  List<Widget> _buildFirebaseDetails(User user, ThemeData theme, bool isDark) {
    return [
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
        icon: Icons.cake_outlined,
        label: 'Age',
        value: user.age == 0 ? '' : user.age.toString(),
        theme: theme,
        isDark: isDark,
      ),
      _buildDivider(isDark),
      _buildDetailTile(
        icon: Icons.phone_outlined,
        label: 'Contact number',
        value: user.contactNo,
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
    ];
  }

  // shows DummyJSON or Firebase under the username.
  Widget _buildLoginTypeBadge(ThemeData theme, bool isFirebase) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: CustomText(
        text: isFirebase ? 'Firebase account' : 'DummyJSON account',
        fontSize: 11.sp,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }

  // one button style used by the three account actions.
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required ThemeData theme,
    required VoidCallback? onPressed,
    bool isDanger = false,
  }) {
    // no onPressed means the action is off, dummyjson accounts.
    final isDisabled = onPressed == null;
    final isDark = theme.brightness == Brightness.dark;

    // grayed out when disabled so it looks unavailable.
    final color = isDisabled
        ? (isDark ? AppColors.darkMuted : AppColors.lightMuted)
        : (isDanger ? theme.colorScheme.error : theme.colorScheme.primary);

    return SizedBox(
      width: double.infinity,
      height: 38.h,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16.sp, color: color),
        label: CustomText(
          text: label,
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color),
          // smaller padding so the button is not too tall.
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
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
