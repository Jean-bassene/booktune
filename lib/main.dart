import 'package:booktune/services/librivox_service.dart';
import 'package:booktune/services/media_notification_service.dart';
import 'package:booktune/services/android_permissions_service.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'providers/audiobook_provider.dart';
import 'providers/player_provider.dart';
import 'services/audio_handler.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuration de l'orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configuration de la barre de statut
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Demander les permissions essentielles au démarrage
  await _requestEssentialPermissions();

  runApp(const MyApp());
}

Future<void> _requestEssentialPermissions() async {
  try {
    // Permissions pour les fichiers
    await AndroidPermissionsService.requestAllPermissions();

    // Permissions pour les notifications (Android 13+)
    await AndroidPermissionsService.requestNotificationPermission();
  } catch (e) {
    print('Erreur lors de la demande de permissions: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<http.Client>(create: (_) => http.Client()),
        ProxyProvider<http.Client, LibrivoxService>(
          update: (context, client, __) => LibrivoxService(httpClient: client),
        ),
        ChangeNotifierProvider(create: (_) => AudiobookProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
      ],
      child: Builder(
        builder: (context) {
          // Initialiser la connexion entre PlayerProvider et AudiobookProvider
          final playerProvider = context.read<PlayerProvider>();
          final audiobookProvider = context.read<AudiobookProvider>();
          playerProvider.setAudiobookProvider(audiobookProvider);

          // Initialiser les notifications modernes
          NotificationService.setPlayerProvider(playerProvider);
          NotificationService.initialize();

          // Afficher le dialogue d'optimisation batterie si nécessaire
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AndroidPermissionsService.showBatteryOptimizationDialog(context);
          });

          return MaterialApp(
            title: 'Booktune',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ),
              scaffoldBackgroundColor: Colors.black,
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
