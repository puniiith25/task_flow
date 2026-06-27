import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/router.dart';
import '../../providers/auth_provider.dart';

class PhoneOtpScreen extends StatefulWidget {
  const PhoneOtpScreen({super.key});

  @override
  State<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends State<PhoneOtpScreen> {
  final _smsController = TextEditingController();
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
    _smsController.dispose();
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

  void _resendSms() async {
    if (!_canResend) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final phone = authProvider.userPhone;
    
    if (phone != null && phone.isNotEmpty) {
      final success = await authProvider.sendPhoneOtp(phone);
      if (mounted) {
        if (success) {
          _startTimer();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('SMS verification code resent successfully.'),
              backgroundColor: AppTheme.primarySeedColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Failed to resend SMS code. Please try again.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }

  void _submit() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.verifyPhoneOtp(_smsController.text.trim());

    if (mounted) {
      if (success) {
        Navigator.pushReplacementNamed(context, AppRouter.avatarSelection);
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
    final phone = authProvider.userPhone ?? "your phone number";
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
                    Icons.security_rounded,
                    size: 80,
                    color: AppTheme.primarySeedColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Verify your phone',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We\'ve triggered an SMS verification code to:\n$phone\n\n(If using test credentials, enter your test code)',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 36),

                  // SMS OTP field
                  TextFormField(
                    controller: _smsController,
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
                        return 'SMS verification code is required';
                      }
                      if (val.trim().length != 6) {
                        return 'Enter the 6-digit SMS code';
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
                        : const Text('Verify Phone', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),

                  // Resend countdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _canResend
                            ? "Didn't receive the SMS? "
                            : "Resend code in $_timerSeconds s ",
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                      if (_canResend)
                        TextButton(
                          onPressed: _resendSms,
                          child: const Text(
                            'Resend SMS',
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
