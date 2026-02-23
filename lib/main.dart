import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/constants/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'core/network/app_router.dart';
import 'core/di/injection_container.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inițializare date locale pentru DateFormat (ro_RO)
  await initializeDateFormatting('ro_RO', null);

  // Setează orientarea portret
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Stil status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Inițializare dependențe
  await initDependencies();

  // Inițializare notificări locale
  await NotificationService.initialize();
  await NotificationService.requestPermissions();

  runApp(const GestionareBunuriApp());
}

class GestionareBunuriApp extends StatelessWidget {
  const GestionareBunuriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
