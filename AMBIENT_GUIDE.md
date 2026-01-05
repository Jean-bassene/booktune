# 🎵 Guide des Ambiances Pré-packagées

## Fichiers inclus

L'application inclut 5 ambiances pré-packagées dans `assets/ambient/` :

### 🌿 Nature
- **rain.mp3** - Pluie douce (3 min)
- **forest.mp3** - Forêt mystique (4 min) 
- **ocean.mp3** - Vagues océan (5 min)

### 🔥 Cosy
- **fireplace.mp3** - Feu de cheminée (3.3 min)

### 🏙️ Urbain
- **cafe.mp3** - Café ambiance (3.7 min)

## Utilisation

1. **Accès** : Bouton "Presets" dans l'écran Lecteur
2. **Sélection** : Tap sur une ambiance pour la lancer
3. **Arrêt** : Bouton "Arrêter" ou tap sur l'icône stop
4. **Volume** : Slider "Musique d'ambiance" dans le lecteur

## Fonctionnalités

- ✅ **Boucle automatique** - Les ambiances se répètent
- ✅ **Synchronisation** - Play/pause avec le livre audio
- ✅ **Volume indépendant** - Mixage parfait
- ✅ **Catégories** - Organisation par thème

## Remplacer par de vrais sons

### Option 1 : Script automatique
```bash
# Exécuter le script de téléchargement
download_ambient_sounds.bat
```

### Option 2 : Manuel
1. Télécharger des sons depuis [freesound.org](https://freesound.org)
2. Convertir en MP3 (128kbps recommandé)
3. Remplacer les fichiers dans `assets/ambient/`
4. Durée recommandée : 2-5 minutes pour des boucles parfaites

### Option 3 : Générateur
```bash
# Régénérer les fichiers de test
dart generate_test_sounds.dart
```

## Format recommandé

- **Format** : MP3, 128kbps
- **Durée** : 2-5 minutes
- **Boucle** : Début et fin compatibles
- **Taille** : < 5MB par fichier

## Ajouter de nouvelles ambiances

Modifier `lib/services/ambient_presets_service.dart` :

```dart
{
  'name': 'Nouvelle ambiance',
  'filePath': 'assets/ambient/nouvelle.mp3',
  'category': 'nature', // ou 'cozy', 'urban'
  'duration': 180,
  'description': 'Description de l\'ambiance',
}
```