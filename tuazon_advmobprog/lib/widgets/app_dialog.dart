import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants.dart';
import 'custom_text.dart';

// one popup design shared by the account actions and the logout buttons,
// so every dialog in the app looks the same.
Widget buildAppDialog({
  required BuildContext dialogContext,
  required String title,
  required List<Widget> fields,
  required String confirmLabel,
  required VoidCallback onConfirm,
  String? message,
  bool isDanger = false,
}) {
  final theme = Theme.of(dialogContext);
  final isDark = theme.brightness == Brightness.dark;
  // delete and logout use the red color, the rest use the teal one.
  final accent = isDanger ? theme.colorScheme.error : theme.colorScheme.primary;

  return AlertDialog(
    backgroundColor: theme.cardTheme.color,
    // same rounded card with a border used on the other screens.
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16.r),
      side: BorderSide(
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      ),
    ),
    titlePadding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 8.h),
    contentPadding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 8.h),
    actionsPadding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
    title: CustomText(
      text: title,
      fontSize: 16.sp,
      fontWeight: FontWeight.bold,
      color: isDanger ? accent : null,
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // short note shown above the boxes, only when there is one.
        if (message != null) ...[
          CustomText(
            text: message,
            fontSize: 12.sp,
            color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
          ),
          SizedBox(height: 16.h),
        ],
        ...fields,
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(dialogContext),
        child: CustomText(
          text: 'Cancel',
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
        ),
      ),
      ElevatedButton(
        onPressed: onConfirm,
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
        child: CustomText(
          text: confirmLabel,
          fontSize: 13.sp,
          fontWeight: FontWeight.bold,
          // matches whichever background color the button is using.
          color: isDanger
              ? theme.colorScheme.onError
              : theme.colorScheme.onPrimary,
        ),
      ),
    ],
  );
}

// text box inside the popup, same design as the sign in screen.
Widget buildDialogField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  required ThemeData theme,
  required bool isDark,
  bool obscure = false,
}) {
  final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
  final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

  return TextField(
    controller: controller,
    obscureText: obscure,
    style: TextStyle(fontFamily: 'Poppins', fontSize: 14.sp),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14.sp,
        color: muted,
      ),
      prefixIcon: Icon(icon, size: 20.sp, color: muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: theme.colorScheme.primary),
      ),
    ),
  );
}
