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
      // Permission de stockage (lecture/écriture legacy)
      final storageStatus = await Permission.storage.request();
      results['storage'] = storageStatus.isGranted;
      results['storageWrite'] = storageStatus.isGranted; // Inclus dans storage

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

      // Permission d'accès aux fichiers audio (Android 13+)
      if (await Permission.audio.isGranted == false) {
        final audioStatus = await Permission.audio.request();
        results['audio'] = audioStatus.isGranted;
      } else {
        results['audio'] = true;
      }

      // Permission d'accès aux fichiers (Android 13+)
      if (await Permission.manageExternalStorage.isGranted == false) {
        final manageStorageStatus =
            await Permission.manageExternalStorage.request();
        results['manageExternalStorage'] = manageStorageStatus.isGranted;
      } else {
        results['manageExternalStorage'] = true;
      }

      // Permission de superposition (overlay)
      try {
        results['systemAlertWindow'] =
            await Permission.systemAlertWindow.isGranted;
      } catch (e) {
        results['systemAlertWindow'] = false;
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

  /// Détecte si c'est un appareil Honor/Huawei avec optimisations agressives
  static Future<bool> isHonorDevice() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      final manufacturer = androidInfo.manufacturer.toLowerCase();
      final brand = androidInfo.brand.toLowerCase();
      final model = androidInfo.model.toLowerCase();

      // Détecter Honor/Huawei
      return manufacturer.contains('huawei') ||
          manufacturer.contains('honor') ||
          brand.contains('huawei') ||
          brand.contains('honor') ||
          model.contains('honor');
    } catch (e) {
      print('Erreur détection Honor: $e');
      return false;
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

  /// Ouvre les paramètres de lancement d'applications (pour Honor/Huawei)
  static Future<void> openAppLaunchSettings() async {
    try {
      await platform.invokeMethod('openAppLaunchSettings');
    } on PlatformException catch (e) {
      print('Erreur ouverture paramètres lancement: ${e.message}');
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

    final isHonor = await isHonorDevice();

    if (!context.mounted) return;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: Row(
            children: [
              Icon(Icons.battery_alert,
                  color:
                      isHonor ? Colors.red.shade400 : Colors.orange.shade400),
              const SizedBox(width: 8),
              Text(
                isHonor
                    ? '⚠️ Honor: Configuration Requise'
                    : 'Optimisation Batterie',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Text(
            isHonor
                ? 'Votre Honor X5 coupe automatiquement l\'audio après 2-3 minutes.\n\n'
                    'Solution CRITIQUE :\n\n'
                    '1. Paramètres > Applications > Booktune\n'
                    '2. "Informations sur l\'app" > Paramètres\n'
                    '3. Lancement d\'applications > Désactiver "Gérée automatiquement"\n'
                    '4. Activer : Démarrage auto + Activité secondaire\n'
                    '5. Paramètres > Batterie > "Pas de restriction"\n\n'
                    '⚠️ Cette étape est ESSENTIELLE pour Honor !'
                : 'Pour une lecture audio continue, Booktune doit être exempté des optimisations de batterie Android.\n\n'
                    'Cela permet à l\'app de fonctionner en arrière-plan sans interruption.',
            style: const TextStyle(color: Colors.white70),
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
              label: Text(isHonor ? 'Configurer Honor' : 'Configurer'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isHonor ? Colors.red.shade600 : Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }
}
