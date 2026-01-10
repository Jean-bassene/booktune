import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

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
}
