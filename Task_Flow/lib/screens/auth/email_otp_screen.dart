import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/router.dart';
import '../../providers/auth_provider.dart';

class EmailOtpScreen extends StatefulWidget {
  const EmailOtpScreen({super.key});

  @override
  State<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends State<EmailOtpScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _timerSeconds = 30;
  Timer? _countdownTimer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _timerSeconds = 30;
      _canResend = false;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds == 0) {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      } else {
        setState(() {
          _timerSeconds--;
        });
      }
    });
  }

  void _resendCode() async {
    if (!_canResend) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = authProvider.userEmail;
    final uid = authProvider.userId;
    
    if (uid != null && email != null) {
      await authProvider.sendEmailOtp(uid, email);
      _startTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Verification code resent successfully. Check console log.'),
            backgroundColor: AppTheme.primarySeedColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _submit() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.verifyEmailOtp(_otpController.text.trim());

    if (mounted) {
      if (success) {
        // Trigger sending Phone SMS OTP
        final phone = authProvider.userPhone ?? '';
        final phoneSent = await authProvider.sendPhoneOtp(phone);
        
        if (mounted) {
          if (phoneSent) {
            Navigator.pushReplacementNamed(context, AppRouter.phoneOtp);
          } else {
            // Even if phone verification fails to trigger, show error, but direct them to Phone Screen so they can try again/resend
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(authProvider.errorMessage ?? 'Failed to send SMS OTP. Please try resending.'),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
            Navigator.pushReplacementNamed(context, AppRouter.phoneOtp);
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Invalid verification code.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final email = authProvider.userEmail ?? "your email";
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pushReplacementNamed(context, AppRouter.login),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.mark_email_read_rounded,
                    size: 80,
                    color: AppTheme.primarySeedColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Verify your email',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We\'ve sent a 6-digit confirmation OTP to:\n$email\n\n(For local testing, check your terminal console logs)',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 36),

                  // OTP field
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8.0,
                    ),
                    maxLength: 6,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '000000',
                      hintStyle: TextStyle(color: Colors.grey[400], letterSpacing: 8.0),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Verification code is required';
                      }
                      if (val.trim().length != 6) {
                        return 'Enter a 6-digit code';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Verify button
                  ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: authProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Verify Email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),

                  // Resend countdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _canResend
                            ? "Didn't receive the code? "
                            : "Resend code in $_timerSeconds s ",
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                      if (_canResend)
                        TextButton(
                          onPressed: _resendCode,
                          child: const Text(
                            'Resend OTP',
                            style: TextStyle(
                              color: AppTheme.primarySeedColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
