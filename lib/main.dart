import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:front_inventarios/pages/login_page.dart';
import 'package:front_inventarios/pages/lock_screen_page.dart';
import 'package:front_inventarios/auth/role_service.dart';
import 'package:front_inventarios/theme.dart';
import 'package:front_inventarios/services/sync_queue_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Iniciar el demonio de sincronización online/offline
  SyncQueueService.instance.startListening();

  // Verificar sesión existente (incluso offline)
  final initialSession = Supabase.instance.client.auth.currentSession;
  final isLoggedIn = initialSession != null;

  if (isLoggedIn) {
    // Restaurar rol (lee de Supabase o SQLite offline)
    await RoleService.fetchAndSetUserRole(initialSession.user.id);
  }

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

final supabase = Supabase.instance.client;

class MyApp extends StatefulWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      SyncQueueService.instance.pausePolling();
    } else if (state == AppLifecycleState.resumed) {
      SyncQueueService.instance.resumePolling();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sistema de Inventarios',
      theme: AppTheme.lightTheme,
      home: widget.isLoggedIn ? const LockScreenPage() : const LoginPage(),
    );
  }
}

extension ContextExtension on BuildContext {
  void showSnackBar(String message, {bool isError = false}) {
    final overlay = Overlay.of(this);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          minimum: const EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isError
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}
