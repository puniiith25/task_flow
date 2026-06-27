import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../main_navigation_scaffold.dart';
import 'login_screen.dart';
import 'email_otp_screen.dart';
import 'avatar_selection_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Show a loading screen while Firebase checks for a cached session
    if (authProvider.isInitializing) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 72,
                color: AppTheme.primarySeedColor,
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    // Direct user based on auth state
    if (authProvider.isAuthenticated) {
      if (!authProvider.isEmailOtpVerified) {
        return const EmailOtpScreen();
      }
      if (authProvider.isNewUser && authProvider.profileImageUrl.isEmpty) {
        return const AvatarSelectionScreen();
      }
      return const MainNavigationScaffold();
    } else {
      return const LoginScreen();
    }
  }
}
