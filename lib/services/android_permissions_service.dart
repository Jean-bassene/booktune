import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

class AndroidPermissionsService {
  static const platform = MethodChannel('com.example.booktune/battery');

  /// Demande toutes les permissions nécessaires pour Android
  static Future<Map<String, bool>> requestAllPermissions() async {
    final Map<String, bool> results = {};

    try {
      // Permission de stockage (pour les fichiers audio locaux)
      final storageStatus = await Permission.storage.request();
      results['storage'] = storageStatus.isGranted;

      // Permission de notifications (Android 13+)
      final notificationStatus = await Permission.notification.request();
      results['notification'] = notificationStatus.isGranted;

      // Permissions média (pour accéder aux fichiers audio)
      if (await Permission.mediaLibrary.isGranted == false) {
        final mediaStatus = await Permission.mediaLibrary.request();
        results['mediaLibrary'] = mediaStatus.isGranted;
      } else {
        results['mediaLibrary'] = true;
      }

      // Permission d'accès aux fichiers (Android 13+)
      if (await Permission.manageExternalStorage.isGranted == false) {
        final manageStorageStatus =
            await Permission.manageExternalStorage.request();
        results['manageExternalStorage'] = manageStorageStatus.isGranted;
      } else {
        results['manageExternalStorage'] = true;
      }
    } catch (e) {
      print('Erreur lors de la demande de permissions: $e');
      results['error'] = false;
    }

    return results;
  }

  /// Vérifie si l'app est exemptée des optimisations de batterie
  static Future<bool> checkBatteryOptimizationExemption() async {
    try {
      final bool isExempted =
          await platform.invokeMethod('isBatteryOptimizationExempted');
      return isExempted;
    } on PlatformException catch (e) {
      print('Erreur vérification exemption batterie: ${e.message}');
      return false;
    }
  }

  /// Demande à l'utilisateur d'exempter l'app des optimisations de batterie
  static Future<bool> requestBatteryOptimizationExemption() async {
    try {
      final bool granted =
          await platform.invokeMethod('requestBatteryOptimizationExemption');
      return granted;
    } on PlatformException catch (e) {
      print('Erreur demande exemption batterie: ${e.message}');
      return false;
    }
  }

  /// Ouvre les paramètres de l'app pour permettre à l'utilisateur de configurer manuellement
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }

  /// Demande spécifiquement la permission de notifications (Android 13+)
  static Future<bool> requestNotificationPermission() async {
    try {
      final notificationStatus = await Permission.notification.request();
      return notificationStatus.isGranted;
    } catch (e) {
      print('Erreur demande permission notifications: $e');
      return false;
    }
  }

  /// Vérifie si toutes les permissions essentielles sont accordées
  static Future<bool> hasAllEssentialPermissions() async {
    final permissions = await requestAllPermissions();
    return permissions['storage'] == true &&
        permissions['notification'] == true;
  }

  /// Affiche un guide pour optimiser les paramètres Android
  static String getAndroidOptimizationGuide() {
    return '''
🔋 OPTIMISATION ANDROID POUR BOOKTUNE

Pour une expérience optimale avec les notifications :

1. 📱 Paramètres → Applications → Booktune → Batterie
   • Désactiver "Optimisation de la batterie"
   • Sélectionner "Sans restriction"

2. 🔔 Paramètres → Applications → Booktune → Notifications
   • Activer toutes les notifications
   • Autoriser les notifications persistantes

3. 🔊 Paramètres → Sons et vibrations → "Ne pas déranger"
   • Autoriser Booktune à sonner en mode silencieux

4. 📂 Paramètres → Applications → Booktune → Stockage
   • Autoriser l'accès aux fichiers multimédias

Ces paramètres garantissent que :
• Les notifications médias fonctionnent en arrière-plan
• La lecture continue même en mode économie d'énergie
• Les contrôles de notification sont toujours disponibles
''';
  }

  /// Vérifie si l'appareil est Android et si c'est une version qui nécessite l'optimisation batterie
  static Future<bool> shouldShowBatteryOptimizationDialog() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      // Android 6.0 (API 23) et supérieur nécessitent souvent cette configuration
      return androidInfo.version.sdkInt >= 23;
    } catch (e) {
      print('Erreur vérification version Android: $e');
      return true; // Par défaut, montrer le dialogue
    }
  }

  /// Ouvre les paramètres de batterie directement
  static Future<void> openBatteryOptimizationSettings() async {
    try {
      await platform.invokeMethod('openBatteryOptimizationSettings');
    } on PlatformException catch (e) {
      print('Erreur ouverture paramètres batterie: ${e.message}');
      // Fallback: ouvrir les paramètres de l'app
      await openAppSettings();
    }
  }

  /// Affiche un dialogue d'avertissement pour l'optimisation batterie
  static Future<void> showBatteryOptimizationDialog(
      BuildContext context) async {
    final shouldShow = await shouldShowBatteryOptimizationDialog();
    if (!shouldShow) return;

    final isExempted = await checkBatteryOptimizationExemption();
    if (isExempted) return; // Déjà exempté

    if (!context.mounted) return;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: Row(
            children: [
              Icon(Icons.battery_alert, color: Colors.orange.shade400),
              const SizedBox(width: 8),
              const Text(
                'Optimisation Batterie',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: const Text(
            'Pour une lecture audio continue, Booktune doit être exempté des optimisations de batterie Android.\n\n'
            'Cela permet à l\'app de fonctionner en arrière-plan sans interruption.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Plus tard',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await openBatteryOptimizationSettings();
              },
              icon: const Icon(Icons.settings),
              label: const Text('Configurer'),
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
