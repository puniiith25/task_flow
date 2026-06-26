# TaskFlow 🚀

TaskFlow is a modern, cross-platform task management application built with Flutter. It helps users organize their daily schedules, manage priorities, and sync tasks in real time using Firebase Cloud Firestore.

---

## 📱 User Features

*   **Task Management (CRUD):** Create, read, update, and delete tasks with detailed parameters:
    *   *Categories:* Work, Personal, Shopping, Health, and Others.
    *   *Priorities:* Low, Medium, and High (with visual indicator tags).
    *   *Due Dates & Status:* Track deadlines and toggle tasks as completed.
*   **Real-time Synchronization:** Instantly sync your tasks across multiple devices via Firebase.
*   **Smart Reminders & Notifications:**
    *   *Task Due Alerts:* Automated local notifications sent directly to your device when tasks are due.
    *   *Daily morning check-in:* Receives a gentle check-in prompt at 9:00 AM to organize your day.
    *   *Cloud Push Notifications:* Integrates Firebase Cloud Messaging (FCM).
*   **Session Persistence:** Close the app and return right where you left off without being logged out.
*   **Rich Dark & Light Themes:** Toggle between dark mode and light mode instantly from settings.

---

## 🛠 Developer Guide

### Tech Stack
*   **Framework:** Flutter (Channel stable, ^3.11.5 Dart SDK)
*   **State Management:** Provider pattern for reactive UI updates.
*   **Database & Sync:** Cloud Firestore (Firebase)
*   **Authentication:** Firebase Auth (Email/Password login, password reset, register)
*   **Notifications:** `flutter_local_notifications` for local scheduling, `timezone` for scheduled alarms, and `firebase_messaging` for cloud push notifications.

---

### Project Architecture & Folder Structure

```text
lib/
├── core/                  # Core configurations, routing & styles
│   ├── router.dart        # Route map (Root AuthWrapper, Login, Dashboard, etc.)
│   └── theme.dart         # Custom Dark/Light theme specifications
├── models/                # Data serialization classes
│   └── task_model.dart    # Task schema mapping to Firestore fields
├── providers/             # ChangeNotifier providers for state management
│   ├── auth_provider.dart
│   ├── task_provider.dart
│   ├── theme_provider.dart
│   └── notification_provider.dart
├── repositories/          # Abstracted data retrieval layer
│   └── task_repository.dart
├── screens/               # User interface screens grouped by feature
│   ├── auth/              # Login, Register, Forgot Password, and AuthWrapper
│   ├── dashboard/         # Home screen widget and Notification center
│   ├── tasks/             # Task listing view and detailed entry sheets
│   ├── settings/          # System preferences, themes, and account settings
│   └── main_navigation_scaffold.dart # Main app layout with navigation bar
├── services/              # Third-party integrations & background systems
│   ├── auth_service.dart  # Direct interaction with Firebase Auth SDK
│   ├── firestore_service.dart # Cloud Firestore sync actions
│   └── notification_service.dart # Local and push notification controller
└── main.dart              # App initialization and dependency loading
```

---

### How to Run Locally

#### Prerequisites
1. Install [Flutter SDK](https://docs.flutter.dev/get-started/install).
2. Install Dart SDK (normally bundled with Flutter).
3. Ensure Android Studio, Xcode, or desktop build tools are set up.

#### Step 1: Clone and Fetch Dependencies
Download the project dependencies:
```bash
flutter pub get
```

#### Step 2: Configure Firebase
To set up Firestore and Auth:
1. Initialize a new project in the [Firebase Console](https://console.firebase.google.com/).
2. Enable **Email/Password Provider** in Authentication.
3. Enable **Cloud Firestore** in test mode or production mode.
4. Run `flutterfire configure` to generate `lib/firebase_options.dart` and register platform config files (`google-services.json`, `GoogleService-Info.plist`).

#### Step 3: Run the App
To run in debug mode:
```bash
flutter run
```

---

### Additional Scripts

#### Regenerating Launcher Icons
To generate app icons for all platforms (Android, iOS, macOS, Windows, Web) from the source icon in `assets/icon/app_icon.png`:
```bash
dart run flutter_launcher_icons
```
*Note: Configuration is specified in [flutter_launcher_icons.yaml](file:///Users/punith25/VS-CODE/taskflow/flutter_launcher_icons.yaml).*

#### Run Static Code Analysis
Ensure syntax and coding conventions match rules in `analysis_options.yaml`:
```bash
flutter analyze
```
