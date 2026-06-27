import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/email_otp_screen.dart';
import '../screens/auth/avatar_selection_screen.dart';
import '../screens/main_navigation_scaffold.dart';
import '../screens/auth/auth_wrapper.dart';

class AppRouter {
  static const String root = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String emailOtp = '/email-otp';
  static const String avatarSelection = '/avatar-selection';

  static Map<String, WidgetBuilder> get routes => {
    root: (context) => const AuthWrapper(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    dashboard: (context) => const MainNavigationScaffold(),
    emailOtp: (context) => const EmailOtpScreen(),
    avatarSelection: (context) => const AvatarSelectionScreen(),
  };
}
