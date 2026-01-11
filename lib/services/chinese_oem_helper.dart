import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper pour gérer les fabricants chinois avec optimisations batterie agressives
class ChineseOEMHelper {
  /// Détecte si c'est un fabricant chinois
  static Future<String?> getManufacturer() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.manufacturer.toLowerCase();
    } catch (e) {
      return null;
    }
  }

  /// Vérifie si c'est un fabricant avec gestion batterie agressive
  static Future<bool> isAggressiveBatteryManagement() async {
    String? manufacturer = await getManufacturer();

    if (manufacturer == null) return false;

    final aggressiveOEMs = [
      'huawei',
      'honor',
      'xiaomi',
      'oppo',
      'vivo',
      'realme',
      'oneplus',
      'samsung', // Un peu moins agressif mais a ses propres paramètres
    ];

    return aggressiveOEMs.any((oem) => manufacturer.contains(oem));
  }

  /// Instructions spécifiques par fabricant
  static Future<Map<String, dynamic>> getInstructions() async {
    String? manufacturer = await getManufacturer();

    if (manufacturer == null) {
      return {
        'title': 'Autoriser la lecture en arrière-plan',
        'steps': [
          'Paramètres > Applications',
          'Sélectionner cette application',
          'Désactiver l\'optimisation de la batterie',
        ],
      };
    }

    // Instructions spécifiques par marque
    if (manufacturer.contains('honor')) {
      return {
        'title': 'Configuration Honor - Arrêt automatique résolu',
        'steps': [
          '1. Paramètres > Applications > Cette app',
          '2. Appuyez sur "Informations sur l\'app"',
          '3. Paramètres > Lancement d\'applications',
          '4. Désactiver "Gérée automatiquement"',
          '5. Activer : Démarrage auto, Activité secondaire, Exécution en arrière-plan',
          '6. Paramètres > Batterie',
          '7. Sélectionner "Pas de restriction"',
        ],
        'critical': true,
        'autoFix': true, // Peut être corrigé automatiquement
      };
    }

    if (manufacturer.contains('xiaomi') || manufacturer.contains('poco')) {
      return {
        'title': 'Configuration Xiaomi/POCO',
        'steps': [
          '1. Paramètres > Applis > Gérer les applis',
          '2. Trouver cette application',
          '3. Économie d\'énergie > Pas de restriction',
          '4. Démarrage auto > Activer',
          '5. Verrouiller l\'app dans les apps récentes (icône cadenas)',
        ],
        'critical': true,
      };
    }

    if (manufacturer.contains('oppo') || manufacturer.contains('realme')) {
      return {
        'title': 'Configuration Oppo/Realme',
        'steps': [
          '1. Paramètres > Batterie > Gestion d\'applis',
          '2. Trouver cette app et désactiver',
          '3. Paramètres > Confidentialité > Gestionnaire d\'autorisation',
          '4. Démarrage auto > Activer pour cette app',
        ],
        'critical': true,
      };
    }

    if (manufacturer.contains('vivo')) {
      return {
        'title': 'Configuration Vivo',
        'steps': [
          '1. Paramètres > Batterie > Gestion consommation en arrière-plan',
          '2. Sélectionner cette app > Autoriser activité en arrière-plan',
          '3. Paramètres > Plus de paramètres > Applications',
          '4. Démarrage auto > Activer',
        ],
        'critical': true,
      };
    }

    if (manufacturer.contains('huawei')) {
      return {
        'title': 'Configuration Huawei',
        'steps': [
          '1. Paramètres > Batterie > Lancement d\'applications',
          '2. Trouver cette app > Gérer manuellement',
          '3. Tout activer (auto-démarrage, activité secondaire, arrière-plan)',
          '4. Paramètres > Applications > Cette app',
          '5. Batterie > Ne pas optimiser',
        ],
        'critical': true,
      };
    }

    if (manufacturer.contains('samsung')) {
      return {
        'title': 'Configuration Samsung',
        'steps': [
          '1. Paramètres > Batterie et maintenance > Batterie',
          '2. Utilisation de la batterie > Plus (⋮)',
          '3. Paramètres > Limites d\'utilisation en arrière-plan',
          '4. Ajouter cette application dans "Apps jamais mises en veille"',
        ],
        'critical': false,
      };
    }

    return {
      'title': 'Autoriser la lecture en arrière-plan',
      'steps': [
        'Paramètres > Applications',
        'Sélectionner cette application',
        'Désactiver l\'optimisation de la batterie',
      ],
    };
  }

  /// Affiche un dialogue adapté au fabricant
  static Future<void> showManufacturerSpecificDialog(
      BuildContext context) async {
    bool isAggressive = await isAggressiveBatteryManagement();

    if (!isAggressive) {
      return; // Pas nécessaire pour d'autres fabricants
    }

    Map<String, dynamic> instructions = await getInstructions();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  instructions['title'],
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (instructions['critical'] == true)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Configuration OBLIGATOIRE pour que la musique continue',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const Text(
                  'Suivez ces étapes pour éviter que la musique s\'arrête :',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...List<Widget>.generate(
                  (instructions['steps'] as List).length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      instructions['steps'][index],
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '💡 Prenez une capture d\'écran de ces instructions',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Compris'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Ouvrir les paramètres de l'app
                _openAppSettings();
              },
              child: const Text('Ouvrir paramètres'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _openAppSettings() async {
    // Cette partie nécessite le package app_settings
    // Ou utilisez android_intent pour ouvrir les paramètres spécifiques
    try {
      const url = 'app-settings:';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    } catch (e) {
      print('Impossible d\'ouvrir les paramètres: $e');
    }
  }
}
