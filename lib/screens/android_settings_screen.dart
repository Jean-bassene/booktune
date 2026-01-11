import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/android_permissions_service.dart';

class AndroidSettingsScreen extends StatefulWidget {
  const AndroidSettingsScreen({super.key});

  @override
  State<AndroidSettingsScreen> createState() => _AndroidSettingsScreenState();
}

class _AndroidSettingsScreenState extends State<AndroidSettingsScreen> {
  Map<String, bool> _permissionsStatus = {};
  bool _isBatteryOptimized = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndOptimizations();
  }

  Future<void> _checkPermissionsAndOptimizations() async {
    setState(() => _isLoading = true);

    try {
      // Vérifier les permissions
      _permissionsStatus =
          await AndroidPermissionsService.requestAllPermissions();

      // Vérifier l'optimisation batterie
      _isBatteryOptimized =
          await AndroidPermissionsService.checkBatteryOptimizationExemption();
    } catch (e) {
      print('Erreur lors de la vérification: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestBatteryOptimizationExemption() async {
    final granted =
        await AndroidPermissionsService.requestBatteryOptimizationExemption();
    if (granted && mounted) {
      setState(() => _isBatteryOptimized = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demande d\'exemption batterie envoyée'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres Android'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900.withOpacity(0.8),
              Colors.blue.shade900,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildPermissionsSection(),
                    const SizedBox(height: 24),
                    _buildBatteryOptimizationSection(),
                    const SizedBox(height: 24),
                    _buildOptimizationGuide(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.android, color: Colors.green.shade400, size: 32),
              const SizedBox(width: 12),
              const Text(
                'Optimisation Android',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Configurez Android pour une expérience optimale avec Booktune',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Permissions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildPermissionItem(
            'Stockage',
            'Accès aux fichiers audio locaux',
            _permissionsStatus['storage'] ?? false,
          ),
          _buildPermissionItem(
            'Notifications',
            'Affichage des contrôles média',
            _permissionsStatus['notification'] ?? false,
          ),
          _buildPermissionItem(
            'Médias',
            'Accès à la bibliothèque musicale',
            _permissionsStatus['mediaLibrary'] ?? false,
          ),
          _buildPermissionItem(
            'Musique et fichiers audio',
            'Accès aux fichiers audio locaux',
            _permissionsStatus['audio'] ?? false,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _checkPermissionsAndOptimizations,
            icon: const Icon(Icons.refresh),
            label: const Text('Vérifier à nouveau'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(String title, String description, bool granted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            granted ? Icons.check_circle : Icons.cancel,
            color: granted ? Colors.green : Colors.red,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryOptimizationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Optimisation Batterie',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Permet à Booktune de fonctionner en arrière-plan',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                _isBatteryOptimized ? Icons.check_circle : Icons.warning,
                color: _isBatteryOptimized ? Colors.green : Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isBatteryOptimized
                      ? 'Exemptée des optimisations batterie'
                      : 'Soumise aux optimisations batterie',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          if (!_isBatteryOptimized) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _requestBatteryOptimizationExemption,
              icon: const Icon(Icons.battery_charging_full),
              label: const Text('Demander exemption'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptimizationGuide() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Guide d\'optimisation',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              AndroidPermissionsService.getAndroidOptimizationGuide(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => AndroidPermissionsService.openAppSettings(),
            icon: const Icon(Icons.settings),
            label: const Text('Ouvrir paramètres'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
