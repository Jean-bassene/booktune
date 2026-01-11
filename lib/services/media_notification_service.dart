import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/audiobook.dart';
import '../models/librivox_book.dart';
import '../providers/player_provider.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static PlayerProvider? _playerProvider;
  static int _currentNotificationId = 0;

  static void setPlayerProvider(PlayerProvider provider) {
    _playerProvider = provider;
  }

  static Future<void> initialize() async {
    // Configuration Android
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuration iOS (si nécessaire plus tard)
    const iosSettings = DarwinInitializationSettings();

    // Initialisation
    await _localNotifications.initialize(
      InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _handleNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _handleNotificationAction,
    );

    // Créer les canaux de notification
    await _createNotificationChannels();
  }

  static Future<void> _createNotificationChannels() async {
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Canal pour les notifications de lecture
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'booktune_playback',
          'Lecture audio BookTune',
          description: 'Notifications de contrôle de lecture audio',
          importance: Importance.low,
          playSound: false,
          enableVibration: false,
          showBadge: false,
        ),
      );

      // Canal pour les notifications importantes
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'booktune_important',
          'Notifications importantes',
          description: 'Notifications importantes de BookTune',
          importance: Importance.high,
        ),
      );
    }
  }

  static Future<void> showPlaybackNotification(
    Audiobook audiobook, {
    String? chapterTitle,
    bool isPlaying = true,
  }) async {
    final title = chapterTitle ?? audiobook.title;
    final subtitle = 'par ${audiobook.author}';

    final androidDetails = AndroidNotificationDetails(
      'booktune_playback',
      'Lecture audio BookTune',
      channelDescription: 'Notifications de contrôle de lecture audio',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      playSound: false,
      enableVibration: false,
      showProgress: true,
      maxProgress: 100,
      progress: 0, // Sera mis à jour séparément
      actions: [
        AndroidNotificationAction(
          isPlaying ? 'pause' : 'play',
          isPlaying ? 'Pause' : 'Play',
        ),
        const AndroidNotificationAction('next', 'Suivant'),
        const AndroidNotificationAction('stop', 'Stop'),
      ],
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      _currentNotificationId,
      title,
      subtitle,
      notificationDetails,
    );
  }

  static Future<void> showPlaybackNotificationFromLibrivox(
    LibrivoxBook book,
    String chapterTitle, {
    bool isPlaying = true,
  }) async {
    final title = chapterTitle;
    final subtitle = 'par ${book.author} • LibriVox';

    final androidDetails = AndroidNotificationDetails(
      'booktune_playback',
      'Lecture audio BookTune',
      channelDescription: 'Notifications de contrôle de lecture audio',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      playSound: false,
      enableVibration: false,
      actions: [
        AndroidNotificationAction(
          isPlaying ? 'pause' : 'play',
          isPlaying ? 'Pause' : 'Play',
        ),
        const AndroidNotificationAction('next', 'Chapitre suivant'),
        const AndroidNotificationAction('stop', 'Stop'),
      ],
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      _currentNotificationId,
      title,
      subtitle,
      notificationDetails,
    );
  }

  static Future<void> updatePlaybackProgress(int progress) async {
    final androidDetails = AndroidNotificationDetails(
      'booktune_playback',
      'Lecture audio BookTune',
      channelDescription: 'Notifications de contrôle de lecture audio',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      playSound: false,
      enableVibration: false,
      showProgress: true,
      maxProgress: 100,
      progress: progress,
    );

    await _localNotifications.show(
      _currentNotificationId,
      null, // Garde le titre actuel
      null, // Garde le sous-titre actuel
      NotificationDetails(android: androidDetails),
    );
  }

  static Future<void> hidePlaybackNotification() async {
    await _localNotifications.cancel(_currentNotificationId);
  }

  static void _handleNotificationTap(NotificationResponse response) async {
    // Gestion du tap sur la notification (ouvre l'app)
    // response.actionId sera null pour un tap simple
    print('Notification tap: ${response.actionId}');
  }

  static void _handleNotificationAction(NotificationResponse response) async {
    final actionId = response.actionId;
    print('🔥 Notification action triggered: $actionId');

    if (_playerProvider == null) {
      print('❌ PlayerProvider not set for notification actions');
      return;
    }

    try {
      switch (actionId) {
        case 'play':
          print('▶️ Action: Play');
          await _playerProvider?.togglePlayPause();
          break;
        case 'pause':
          print('⏸️ Action: Pause');
          await _playerProvider?.togglePlayPause();
          break;
        case 'next':
          print('⏭️ Action: Next chapter');
          await _playerProvider?.playNextChapter();
          break;
        case 'stop':
          print('⏹️ Action: Stop');
          await _playerProvider?.togglePlayPause();
          await hidePlaybackNotification();
          break;
        default:
          print('❓ Unknown action: $actionId');
      }
    } catch (e) {
      print('❌ Error handling notification action: $e');
    }
  }

  static Future<void> showWelcomeNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'booktune_important',
      'Notifications importantes',
      channelDescription: 'Notifications importantes de BookTune',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      999,
      'Bienvenue sur BookTune !',
      'Votre lecteur audio avec musique d\'ambiance',
      notificationDetails,
    );
  }
}
