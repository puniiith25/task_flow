class AppConfig {
  // ==========================================
  // EMAIL CONFIGURATION (EmailJS) - RECOMMENDED FOR PRODUCTION
  // Set these values to connect your app to EmailJS (https://www.emailjs.com)
  // ==========================================
  static const String emailJsServiceId =
      "service_bdfpobf"; // e.g. "service_xxxxxxx"
  static const String emailJsTemplateId =
      "template_r7w8jaa"; // e.g. "template_xxxxxxx"
  static const String emailJsPublicKey = "";
  // "MBuCjIAPQhg0hCVhP"; // e.g. "user_xxxxxxxxxxxxxxx"

  // ==========================================
  // EMAIL CONFIGURATION (Direct SMTP) - ALTERNATIVE
  // Securely set your SMTP credentials here if you prefer direct mail sending
  // ==========================================
  static const String smtpHost = "smtp.gmail.com";
  static const int smtpPort = 587;
  static const String smtpUsername =
      "puniiith25@gmail.com"; // e.g. "your-email@gmail.com"
  static const String smtpPassword =
      "qxwgmgretzcvjeir"; // e.g. "your-app-specific-password"
  static const String senderName = "TaskFlow Security";

  // ==========================================
  // FIREBASE APP CHECK CONFIGURATION
  // ==========================================
  static const String recaptchaV3SiteKey =
      "6LdQ0zctAAAAAOvNWtPSWOfBZVkWUHzifJWRIzYm"; // e.g. "6Lef-xxxxxxxxxxxxxxxxxxxxxxxx"
}
