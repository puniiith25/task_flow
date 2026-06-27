# TaskFlow 🚀

TaskFlow is a modern, premium cross-platform task management application built with Flutter. It helps users organize their daily schedules, manage priorities, track deadlines, and sync tasks in real time using Firebase Cloud Firestore.

---

## 📱 Features

### User Features
*   **Persistent User Session:** Sign in once using Firebase Email & Password. The app remembers your login session across restarts, meaning you will not get auto-logged out when the app is closed.
*   **Task Management (CRUD):** 
    *   Create, view, edit, and delete tasks instantly.
    *   Organize tasks into **Categories** (*Work, Personal, Shopping, Health, and Others*).
    *   Set **Priorities** (*Low, Medium, High*) with visual indicators.
    *   Toggle task completion status dynamically.
*   **Real-time Synchronization:** Synchronize task modifications instantly across all active devices via Google Cloud Firestore.
*   **Swipe-to-Delete Notifications:** Manage incoming alerts in the Notification Center with native swipe-left gestures to delete single notification items from history.
*   **Smart Reminders:**
    *   *Task Due Alerts:* Trigger local sound and alert notifications when tasks reach their due dates.
    *   *Daily Check-in:* Receive a gentle summary notification every morning at 9:00 AM.
    *   *FCM Support:* Configured for Firebase Cloud Messaging push alerts.
*   **Premium Dark & Light Themes:**
    *   Seamlessly switch dark and light modes from Settings.
    *   Coordinated styling for the top **AppBar** and bottom **NavigationBar** (transparent body-blend in dark mode, clean full-white in light mode).
*   **Jitter-Free Custom Input Controls:** Dropdown fields (Category, Priority, and Status) are fully styled with custom icons, color markers, and a static `16px` border radius mapping that stays fluid without shifting or layout jumps when focused.

---

## 🛠 Developer Guide

### Tech Stack
*   **Framework:** Flutter (Channel stable, ^3.11.5 Dart SDK)
*   **State Management:** Provider pattern (`ChangeNotifierProvider`)
*   **Backend Support:** Firebase Auth & Cloud Firestore
*   **Reminders Plugin:** `flutter_local_notifications` + `timezone` data scheduling
*   **Icon Generator:** `flutter_launcher_icons` for multi-platform assets

---

### Project Architecture & Folder Structure

```text
lib/
├── core/                  # Global styling, themes & routing
│   ├── router.dart        # Route registry (Root AuthWrapper, Login, Dashboard, etc.)
│   └── theme.dart         # Custom Dark/Light theme values
├── models/                # Serialization structures
│   └── task_model.dart    # Task schema mapping to Firestore fields
├── providers/             # ChangeNotifier controllers for state logic
│   ├── auth_provider.dart
│   ├── task_provider.dart
│   ├── theme_provider.dart
│   └── notification_provider.dart
├── repositories/          # Abstracted data retrieval layer
│   └── task_repository.dart
├── screens/               # Feature-specific layouts and screens
│   ├── auth/              # Login, Register, Forgot Password, and AuthWrapper
│   ├── dashboard/         # Home feed widget & Notification center
│   ├── tasks/             # Task listing views & TaskDetailSheet forms
│   ├── settings/          # Theme toggle and logout configuration
│   └── main_navigation_scaffold.dart # Base layout containing bottom navigation bar
├── services/              # Subsystem modules & SDK overlays
│   ├── auth_service.dart  # Direct interaction with Firebase Auth SDK
│   ├── firestore_service.dart # Cloud Firestore sync operations
│   └── notification_service.dart # Local and push notification scheduler
└── main.dart              # Main setup entry point
```

---

### How to Run Locally

#### Prerequisites
1. Install [Flutter SDK](https://docs.flutter.dev/get-started/install).
2. Set up simulator, emulator, or physical device targets.

#### Step 1: Install Dependencies
Open the project directory and fetch packages:
```bash
flutter pub get
```

#### Step 2: Configure Firebase Credentials
1. Create a Firebase project in the [Firebase Console](https://console.firebase.google.com/).
2. Enable **Email/Password Provider** in Authentication.
3. Start **Cloud Firestore** in test or production mode.
4. Run `flutterfire configure` to generate `lib/firebase_options.dart` and bind native assets (`google-services.json` on Android, `GoogleService-Info.plist` on iOS/macOS).

#### Step 3: Run the Application
Start debugging the app:
```bash
flutter run
```

---

### Development Scripts

#### Generate App Launcher Icons
Generate responsive, correctly-formatted launcher icons from `assets/icon/app_icon.png` for all platforms:
```bash
dart run flutter_launcher_icons
```
*Note: Configured in [flutter_launcher_icons.yaml](file:///Users/punith25/VS-CODE/taskflow/Task_Flow/flutter_launcher_icons.yaml).*

#### Run Static Code Analysis
Audit code formatting and linting rules:
```bash
flutter analyze
```
