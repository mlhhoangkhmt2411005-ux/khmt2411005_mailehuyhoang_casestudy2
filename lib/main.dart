import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/tasks/task_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isLoggedIn = await AuthService.checkLoggedIn();
  runApp(TaskManagerApp(isLoggedIn: isLoggedIn));
}

class TaskManagerApp extends StatelessWidget {
  final bool isLoggedIn;

  const TaskManagerApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskManager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: isLoggedIn ? const TaskListScreen() : const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
