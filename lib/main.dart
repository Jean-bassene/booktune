import 'package:booktune/services/librivox_service.dart';
import 'package:booktune/services/media_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'providers/audiobook_provider.dart';
import 'providers/player_provider.dart';
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

  runApp(const MyApp());
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

          // TODO: Réactiver les notifications médias après correction des erreurs audio_service
          // MediaNotificationService.setPlayerProvider(playerProvider);
          // MediaNotificationService.init();

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
