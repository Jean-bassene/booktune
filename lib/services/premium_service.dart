import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Service de gestion des fonctionnalités premium
class PremiumService with ChangeNotifier {
  static const String _premiumKey = 'is_premium_user';
  static const String _premiumExpiryKey = 'premium_expiry_date';
  static const String _librivoxDownloadsKey = 'librivox_downloads_count';
  static const String _customAmbiencesKey = 'custom_ambiences_count';

  // Limites Freemium
  static const int maxLibrivoxDownloads = 5;
  static const int maxCustomAmbiences = 3;

  bool _isPremium = false;
  DateTime? _premiumExpiry;
  int _librivoxDownloadsCount = 0;
  int _customAmbiencesCount = 0;

  bool get isPremium => _isPremium;
  DateTime? get premiumExpiry => _premiumExpiry;
  int get librivoxDownloadsCount => _librivoxDownloadsCount;
  int get customAmbiencesCount => _customAmbiencesCount;

  /// Vérifie si l'utilisateur peut télécharger un livre LibriVox
  bool get canDownloadLibrivox {
    return _isPremium || _librivoxDownloadsCount < maxLibrivoxDownloads;
  }

  /// Vérifie si l'utilisateur peut importer une ambiance personnalisée
  bool get canImportAmbience {
    return _isPremium || _customAmbiencesCount < maxCustomAmbiences;
  }

  /// Nombre de téléchargements restants pour LibriVox
  int get remainingLibrivoxDownloads {
    if (_isPremium) return -1; // Illimité
    return maxLibrivoxDownloads - _librivoxDownloadsCount;
  }

  /// Nombre d'imports d'ambiances restants
  int get remainingCustomAmbiences {
    if (_isPremium) return -1; // Illimité
    return maxCustomAmbiences - _customAmbiencesCount;
  }

  /// Initialise le service en chargeant les données sauvegardées
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    _isPremium = prefs.getBool(_premiumKey) ?? false;

    final expiryTimestamp = prefs.getInt(_premiumExpiryKey);
    if (expiryTimestamp != null) {
      _premiumExpiry = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
      // Vérifier si l'abonnement a expiré
      if (_premiumExpiry!.isBefore(DateTime.now())) {
        await _revokePremium();
      }
    }

    _librivoxDownloadsCount = prefs.getInt(_librivoxDownloadsKey) ?? 0;
    _customAmbiencesCount = prefs.getInt(_customAmbiencesKey) ?? 0;

    notifyListeners();
  }

  /// Active le statut premium (abonnement acheté)
  Future<void> activatePremium({Duration? subscriptionDuration}) async {
    final prefs = await SharedPreferences.getInstance();

    _isPremium = true;
    _premiumExpiry = subscriptionDuration != null
        ? DateTime.now().add(subscriptionDuration)
        : null; // Abonnement permanent

    await prefs.setBool(_premiumKey, _isPremium);
    if (_premiumExpiry != null) {
      await prefs.setInt(
          _premiumExpiryKey, _premiumExpiry!.millisecondsSinceEpoch);
    }

    notifyListeners();
  }

  /// Révoque le statut premium (expiration ou annulation)
  Future<void> _revokePremium() async {
    final prefs = await SharedPreferences.getInstance();

    _isPremium = false;
    _premiumExpiry = null;

    await prefs.setBool(_premiumKey, false);
    await prefs.remove(_premiumExpiryKey);

    notifyListeners();
  }

  /// Incrémente le compteur de téléchargements LibriVox
  Future<void> incrementLibrivoxDownloads() async {
    if (_isPremium) return; // Pas de limite pour premium

    _librivoxDownloadsCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_librivoxDownloadsKey, _librivoxDownloadsCount);

    notifyListeners();
  }

  /// Incrémente le compteur d'imports d'ambiances
  Future<void> incrementCustomAmbiences() async {
    if (_isPremium) return; // Pas de limite pour premium

    _customAmbiencesCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_customAmbiencesKey, _customAmbiencesCount);

    notifyListeners();
  }

  /// Réinitialise les compteurs (pour tests ou reset)
  Future<void> resetCounters() async {
    _librivoxDownloadsCount = 0;
    _customAmbiencesCount = 0;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_librivoxDownloadsKey, 0);
    await prefs.setInt(_customAmbiencesKey, 0);

    notifyListeners();
  }

  /// Vérifie si l'abonnement premium est expiré
  bool get isPremiumExpired {
    if (!_isPremium || _premiumExpiry == null) return false;
    return _premiumExpiry!.isBefore(DateTime.now());
  }

  /// Obtient le message d'état premium
  String get premiumStatusMessage {
    if (_isPremium) {
      if (_premiumExpiry == null) {
        return 'Premium activé (permanent)';
      } else {
        final daysLeft = _premiumExpiry!.difference(DateTime.now()).inDays;
        return 'Premium activé (${daysLeft} jours restants)';
      }
    } else {
      return 'Version gratuite';
    }
  }

  /// Simule un achat premium (pour développement/tests)
  Future<void> simulatePremiumPurchase() async {
    await activatePremium(subscriptionDuration: const Duration(days: 30));
  }

  /// Vérifie si une fonctionnalité est disponible
  bool isFeatureAvailable(String feature) {
    switch (feature) {
      case 'playback_speed':
      case 'sleep_timer':
        return _isPremium;
      case 'librivox_download':
        return canDownloadLibrivox;
      case 'custom_ambience':
        return canImportAmbience;
      default:
        return true; // Fonctionnalités gratuites par défaut
    }
  }

  /// Obtient le message de limitation pour une fonctionnalité
  String getLimitationMessage(String feature) {
    if (_isPremium) return '';

    switch (feature) {
      case 'librivox_download':
        return 'Téléchargement limité à $maxLibrivoxDownloads livres LibriVox. Passez premium pour télécharger illimitivement !';
      case 'custom_ambience':
        return 'Import limité à $maxCustomAmbiences ambiances personnalisées. Passez premium pour importer sans limite !';
      case 'playback_speed':
        return 'La vitesse de lecture personnalisable est réservée aux utilisateurs premium.';
      case 'sleep_timer':
        return 'Le minuteur de sommeil est réservé aux utilisateurs premium.';
      default:
        return 'Cette fonctionnalité est réservée aux utilisateurs premium.';
    }
  }
}

/// Singleton instance
final premiumService = PremiumService();
