import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../core/config.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();

  factory EmailService() => _instance;

  EmailService._internal();

  /// Sends a 6-digit OTP verification email to the user
  Future<bool> sendOtpEmail({
    required String toEmail,
    required String otp,
  }) async {
    // 1. Try EmailJS Integration if credentials are set
    if (AppConfig.emailJsServiceId.isNotEmpty &&
        AppConfig.emailJsTemplateId.isNotEmpty &&
        AppConfig.emailJsPublicKey.isNotEmpty) {
      return await _sendViaEmailJs(toEmail: toEmail, otp: otp);
    }

    // 2. Try Direct SMTP Integration if credentials are set
    if (AppConfig.smtpUsername.isNotEmpty && AppConfig.smtpPassword.isNotEmpty) {
      return await _sendViaSmtp(toEmail: toEmail, otp: otp);
    }

    // 3. Development Fallback (If not configured, log to console warning)
    debugPrint("==================================================");
    debugPrint("⚠️ AppConfig Email credentials not set!");
    debugPrint("To send real emails, set your credentials in lib/core/config.dart");
    debugPrint("Logged OTP to console for debugging: $otp");
    debugPrint("==================================================");
    
    return true;
  }

  /// Sends email using EmailJS REST API
  Future<bool> _sendViaEmailJs({
    required String toEmail,
    required String otp,
  }) async {
    try {
      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'origin': 'localhost',
        },
        body: json.encode({
          'service_id': AppConfig.emailJsServiceId,
          'template_id': AppConfig.emailJsTemplateId,
          'user_id': AppConfig.emailJsPublicKey,
          'template_params': {
            'to_email': toEmail,
            'otp_code': otp,
            'app_name': 'TaskFlow',
          },
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('EmailJS OTP email successfully sent to $toEmail.');
        return true;
      } else {
        debugPrint('EmailJS sending failed with status: ${response.statusCode}, body: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error sending email via EmailJS: $e');
      return false;
    }
  }

  /// Sends email directly using mailer SMTP package
  Future<bool> _sendViaSmtp({
    required String toEmail,
    required String otp,
  }) async {
    try {
      // Setup SMTP server connection
      final smtpServer = gmailOrOther(
        AppConfig.smtpUsername,
        AppConfig.smtpPassword,
      );

      // Create message package
      final message = Message()
        ..from = Address(AppConfig.smtpUsername, AppConfig.senderName)
        ..recipients.add(toEmail)
        ..subject = '🔐 TaskFlow OTP Verification Code'
        ..text = 'Hello,\n\nYour security verification OTP code is: $otp\nThis code will expire in 10 minutes.\n\nBest regards,\nThe TaskFlow Team'
        ..html = '''
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #e5e7eb; border-radius: 12px;">
            <h2 style="color: #6366F1; text-align: center;">TaskFlow Verification</h2>
            <hr style="border: 0; border-top: 1px solid #e5e7eb; margin: 20px 0;">
            <p>Hello,</p>
            <p>Thank you for signing up for TaskFlow. To verify your email address, please use the following 6-digit One-Time Password (OTP):</p>
            <div style="text-align: center; margin: 30px 0;">
              <span style="font-size: 32px; font-weight: bold; color: #111827; letter-spacing: 4px; padding: 12px 24px; background-color: #f3f4f6; border-radius: 8px; border: 1px dashed #6366F1;">
                $otp
              </span>
            </div>
            <p style="color: #6b7280; font-size: 14px;">This code will expire in 10 minutes. If you did not request this code, please ignore this email.</p>
            <hr style="border: 0; border-top: 1px solid #e5e7eb; margin: 20px 0;">
            <p style="text-align: center; color: #9ca3af; font-size: 12px;">© ${DateTime.now().year} TaskFlow. All rights reserved.</p>
          </div>
        ''';

      // Send the email
      await send(message, smtpServer);
      debugPrint('SMTP OTP email successfully sent to $toEmail.');
      return true;
    } catch (e) {
      debugPrint('Error sending email via SMTP: $e');
      return false;
    }
  }

  /// Helper to choose SMTP server (Gmail or Custom)
  SmtpServer gmailOrOther(String username, String password) {
    if (AppConfig.smtpHost.contains("gmail.com")) {
      return gmail(username, password);
    } else {
      return SmtpServer(
        AppConfig.smtpHost,
        port: AppConfig.smtpPort,
        username: username,
        password: password,
      );
    }
  }
}
