import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gigil/providers/auth_provider.dart';
import 'package:gigil/providers/room_provider.dart';
import 'package:gigil/screens/auth/login_screen.dart';
import 'package:gigil/screens/auth/register_screen.dart';
import 'package:gigil/screens/home/dashboard_screen.dart';
import 'package:gigil/screens/room/room_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RoomProvider()),
      ],
      child: const ListenTogetherApp(),
    ),
  );
}

class ListenTogetherApp extends StatelessWidget {
  const ListenTogetherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gigil',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepPurpleAccent,
          secondary: Colors.tealAccent,
        ),
        appBarTheme: const AppBarTheme(
          color: Color(0xFF1F1F1F),
          elevation: 0,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/room': (context) => const RoomScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isAuthenticated) {
          return const DashboardScreen();
        } else if (!auth.isInit) {
          return FutureBuilder(
            future: auth.tryAutoLogin(),
            builder: (ctx, snapshot) =>
                const Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
