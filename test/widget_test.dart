import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:taskflow/main.dart';
import 'package:taskflow/providers/theme_provider.dart';
import 'package:taskflow/providers/auth_provider.dart';
import 'package:taskflow/providers/task_provider.dart';
import 'package:taskflow/providers/notification_provider.dart';
import 'package:taskflow/models/task_model.dart';
import 'package:taskflow/repositories/auth_repository.dart';
import 'package:taskflow/repositories/task_repository.dart';
import 'package:taskflow/services/auth_service.dart';
import 'package:taskflow/services/notification_service.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  Stream<MockUser?> get authStateChanges => const Stream.empty();

  @override
  MockUser? get currentUser => null;

  @override
  Future<MockUser?> signIn(String email, String password) async {
    return null;
  }

  @override
  Future<MockUser?> signUp(String email, String password) async {
    return null;
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> signOut() async {}
}

class FakeTaskRepository implements TaskRepository {
  @override
  Stream<List<TaskModel>> getTasks(String userId) => const Stream.empty();

  @override
  Future<void> addTask(String userId, TaskModel task) async {}

  @override
  Future<void> updateTask(String userId, TaskModel task) async {}

  @override
  Future<void> deleteTask(String userId, String taskId) async {}
}

class FakeNotificationService implements NotificationService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {}

  @override
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {}

  @override
  Future<void> cancelTaskReminder(String taskId) async {}

  @override
  Future<void> scheduleDailyReminder({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> cancelAllNotifications() async {}
}

void main() {
  testWidgets('TaskFlow login screen smoke test', (WidgetTester tester) async {
    final authRepository = FakeAuthRepository();
    final taskRepository = FakeTaskRepository();
    final notificationService = FakeNotificationService();

    // Build our app with providers and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),
          ChangeNotifierProvider(create: (_) => TaskProvider(taskRepository, notificationService)),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ],
        child: const TaskFlowApp(),
      ),
    );

    // Verify that our login screen elements exist on the screen.
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Log in to your TaskFlow account to manage daily tasks. Use test@test.com & password to sign in.'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
