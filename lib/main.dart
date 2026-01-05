import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/audiobook_provider.dart';
import 'providers/player_provider.dart';
import 'providers/tts_provider.dart';
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
        ChangeNotifierProvider(create: (_) => AudiobookProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider(create: (_) => TtsProvider()),
      ],
      child: Builder(
        builder: (context) {
          // Initialiser la connexion entre PlayerProvider et AudiobookProvider
          final playerProvider = context.read<PlayerProvider>();
          final audiobookProvider = context.read<AudiobookProvider>();
          playerProvider.setAudiobookProvider(audiobookProvider);

          return MaterialApp(
            title: 'Audiobook Mixer',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.purple,
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
