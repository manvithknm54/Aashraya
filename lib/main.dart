import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/role_selection_screen.dart';
import 'features/elder/screens/elder_dashboard.dart';
import 'features/caretaker/screens/caretaker_dashboard.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFFBF7F2),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const AashrayaApp());
}

class AashrayaApp extends StatelessWidget {
  const AashrayaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aashraya',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const AppEntryPoint(),
    );
  }
}

class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({super.key});

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 3600), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) return const SplashScreen();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still loading auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF5EFE6),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFD4845A),
                strokeWidth: 2,
              ),
            ),
          );
        }

        // Not logged in
        if (!snapshot.hasData || snapshot.data == null) {
          return const RoleSelectionScreen();
        }

        // Logged in — get role and navigate
        return FutureBuilder<String?>(
          future: AuthService().getUserRole(),
          builder: (context, roleSnap) {
            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFFF5EFE6),
                body: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFD4845A),
                    strokeWidth: 2,
                  ),
                ),
              );
            }
            if (roleSnap.data == 'elder') {
              return const ElderDashboard();
            } else if (roleSnap.data == 'caretaker') {
              return const CaretakerDashboard();
            }
            return const RoleSelectionScreen();
          },
        );
      },
    );
  }
}