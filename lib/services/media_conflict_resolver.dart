import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'logging_service.dart';

/// Gestionnaire de conflits média entre BookTune et autres apps musicales
class MediaConflictResolver {
  static const platform = MethodChannel('com.example.booktune/media_conflict');
  static Timer? _conflictCheckTimer;
  static bool _isHandlingConflict = false;
  static bool _hasAudioFocus = true;

  /// État des conflits détectés
  static final Map<String, dynamic> _conflictState = {
    'hasConflict': false,
    'conflictingApps': <String>[],
    'lastConflictTime': null,
    'userNotified': false,
  };

  /// Initialise la surveillance des conflits média
  static Future<void> initialize() async {
    LoggingService.i('MediaConflictResolver initialisé');

    // Démarrer la surveillance périodique
    _startConflictMonitoring();

    // Écouter les changements de focus audio
    _setupAudioFocusListener();
  }

  /// Démarre la surveillance des conflits
  static void _startConflictMonitoring() {
    _conflictCheckTimer?.cancel();
    _conflictCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkForConflicts();
    });
  }

  /// Configure l'écouteur de focus audio
  static Future<void> _setupAudioFocusListener() async {
    try {
      // Écouter les changements de focus audio depuis la plateforme
      platform.setMethodCallHandler(_handlePlatformCall);
    } catch (e) {
      LoggingService.e('Erreur configuration écouteur focus audio', e);
    }
  }

  /// Gère les appels depuis la plateforme native
  static Future<dynamic> _handlePlatformCall(MethodCall call) async {
    switch (call.method) {
      case 'onAudioFocusLost':
        await _handleAudioFocusLost();
        break;
      case 'onAudioFocusGained':
        await _handleAudioFocusGained();
        break;
      case 'onOtherAppPlaying':
        await _handleOtherAppPlaying(call.arguments as String?);
        break;
      default:
        LoggingService.w('Méthode non reconnue: ${call.method}');
    }
  }

  /// Vérifie périodiquement les conflits
  static Future<void> _checkForConflicts() async {
    if (_isHandlingConflict) return;

    try {
      final result = await platform.invokeMethod('checkMediaConflicts');
      if (result is Map) {
        _updateConflictState(result);
      }
    } catch (e) {
      LoggingService.d('Erreur vérification conflits: $e');
    }
  }

  /// Met à jour l'état des conflits
  static void _updateConflictState(Map<dynamic, dynamic> result) {
    final hasConflict = result['hasConflict'] as bool? ?? false;
    final conflictingApps =
        (result['conflictingApps'] as List?)?.cast<String>() ?? [];

    _conflictState['hasConflict'] = hasConflict;
    _conflictState['conflictingApps'] = conflictingApps;
    _conflictState['lastConflictTime'] = DateTime.now();

    if (hasConflict && !_conflictState['userNotified']) {
      LoggingService.w('Conflit média détecté avec: $conflictingApps');
      _notifyUserOfConflict(conflictingApps);
    } else if (!hasConflict && _conflictState['userNotified']) {
      LoggingService.i('Conflit média résolu');
      _conflictState['userNotified'] = false;
    }
  }

  /// Gère la perte de focus audio
  static Future<void> _handleAudioFocusLost() async {
    LoggingService.w('Focus audio perdu');
    _hasAudioFocus = false;

    // Notifier l'utilisateur si nécessaire
    if (!_isHandlingConflict) {
      _showAudioFocusLostNotification();
    }
  }

  /// Gère le gain de focus audio
  static Future<void> _handleAudioFocusGained() async {
    LoggingService.i('Focus audio récupéré');
    _hasAudioFocus = true;

    // Masquer la notification de conflit si elle existe
    await _hideConflictNotification();
  }

  /// Gère quand une autre app commence à jouer
  static Future<void> _handleOtherAppPlaying(String? appName) async {
    if (appName != null) {
      LoggingService.w('Autre app détectée: $appName');
      _showOtherAppPlayingNotification(appName);
    }
  }

  /// Notifie l'utilisateur d'un conflit
  static void _notifyUserOfConflict(List<String> conflictingApps) {
    _conflictState['userNotified'] = true;
    _showConflictDialog(conflictingApps);
  }

  /// Affiche une notification de perte de focus audio
  static Future<void> _showAudioFocusLostNotification() async {
    try {
      await platform.invokeMethod('showAudioFocusLostNotification');
    } catch (e) {
      LoggingService.e('Erreur affichage notification focus perdu', e);
    }
  }

  /// Affiche une notification pour une autre app qui joue
  static Future<void> _showOtherAppPlayingNotification(String appName) async {
    try {
      await platform.invokeMethod('showOtherAppPlayingNotification', {
        'appName': appName,
      });
    } catch (e) {
      LoggingService.e('Erreur affichage notification autre app', e);
    }
  }

  /// Masque la notification de conflit
  static Future<void> _hideConflictNotification() async {
    try {
      await platform.invokeMethod('hideConflictNotification');
    } catch (e) {
      LoggingService.e('Erreur masquage notification conflit', e);
    }
  }

  /// Affiche un dialogue de conflit à l'utilisateur
  static void _showConflictDialog(List<String> conflictingApps) {
    // Cette méthode sera appelée depuis l'UI
    // Pour l'instant, on log seulement
    LoggingService.i('Conflit détecté avec: $conflictingApps');
  }

  /// Tente de récupérer le focus audio
  static Future<bool> requestAudioFocus() async {
    try {
      final result = await platform.invokeMethod('requestAudioFocus');
      final gained = result as bool? ?? false;

      if (gained) {
        LoggingService.i('Focus audio récupéré avec succès');
        _hasAudioFocus = true;
        await _hideConflictNotification();
      } else {
        LoggingService.w('Impossible de récupérer le focus audio');
      }

      return gained;
    } catch (e) {
      LoggingService.e('Erreur récupération focus audio', e);
      return false;
    }
  }

  /// Vérifie si BookTune a le focus audio
  static bool get hasAudioFocus => _hasAudioFocus;

  /// Vérifie s'il y a un conflit actif
  static bool get hasConflict =>
      _conflictState['hasConflict'] as bool? ?? false;

  /// Obtient la liste des apps en conflit
  static List<String> get conflictingApps =>
      List<String>.from(_conflictState['conflictingApps'] as List? ?? []);

  /// Nettoie les ressources
  static void dispose() {
    _conflictCheckTimer?.cancel();
    _conflictCheckTimer = null;
    LoggingService.i('MediaConflictResolver disposed');
  }

  /// Méthode pour l'UI - affiche un dialogue de résolution de conflit
  static Future<void> showConflictResolutionDialog(BuildContext context) async {
    if (!hasConflict) return;

    final conflictingApps = MediaConflictResolver.conflictingApps;

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange.shade400),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Conflit avec autre app musicale',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                conflictingApps.isNotEmpty
                    ? 'Conflit détecté avec: ${conflictingApps.join(", ")}'
                    : 'Une autre application contrôle actuellement la lecture audio.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              const Text(
                'Que souhaitez-vous faire ?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Continuer avec l\'autre app',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                final gained = await requestAudioFocus();
                if (gained && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contrôle audio récupéré'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Impossible de récupérer le contrôle audio'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.music_note),
              label: const Text('Reprendre le contrôle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }
}
