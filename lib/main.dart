import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'services/notification_service.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/role_selection_screen.dart';
import 'features/auth/screens/link_caretaker_screen.dart';
import 'features/elder/screens/elder_dashboard.dart';
import 'features/caretaker/screens/caretaker_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.init();
  await NotificationService.scheduleEveningReport();

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
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) return const SplashScreen();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return _loader();
        if (!snapshot.hasData) return const RoleSelectionScreen();

        return FutureBuilder<Map<String, dynamic>?>(
          key: ValueKey(snapshot.data!.uid),
          future: _getUserData(snapshot.data!.uid),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) return _loader();

            final data = snap.data;
            if (data == null) return const RoleSelectionScreen();

            final role = data['role'] as String?;
            final linkedTo = data['linkedTo'];
            final isLinked = linkedTo != null && linkedTo.toString().trim().isNotEmpty;

            if (role == 'elder') {
              return isLinked ? const ElderDashboard() : const LinkCaretakerScreen();
            } else if (role == 'caretaker') {
              return const CaretakerDashboard();
            }

            return const RoleSelectionScreen();
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _getUserData(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.serverAndCache));
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  Widget _loader() {
    return const Scaffold(
      backgroundColor: Color(0xFFF5EFE6),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFFD4845A), strokeWidth: 2),
      ),
    );
  }
}