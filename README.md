# 📖 BookTune - Audiobook Player & Library

**Une application mobile révolutionnaire pour écouter vos livres audio avec une expérience immersive personnalisable.**

BookTune combine une bibliothèque personnelle d'audiobooks avec un catalogue gratuit de +15,000 livres LibriVox, le tout agrémenté de musiques d'ambiance pour une expérience d'écoute unique.

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?style=flat&logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-000000?style=flat)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 🌟 **Fonctionnalités Principales**

### 📚 **Bibliothèque Personnelle**
- **Import local** : Fichiers MP3, M4A, OGG, FLAC, WAV depuis votre téléphone
- **Organisation intelligente** : Tri par titre, auteur, date, progression
- **Recherche avancée** : Filtrage dans toute votre bibliothèque
- **Favoris** : Marquage et gestion de vos livres préférés
- **Statistiques** : Suivi de votre temps d'écoute et progression

### 🌐 **Catalogue LibriVox Intégré**
- **+15,000 livres gratuits** : Bibliothèque publique internationale
- **Recherche intelligente** : Par titre, auteur, langue
- **Téléchargement direct** : Chapitre par chapitre ou livre complet
- **Cache performant** : Accès offline aux métadonnées
- **Mises à jour automatiques** : Synchronisation avec l'API LibriVox

### 🎧 **Lecteur Audio Professionnel**
- **Formats supportés** : MP3, M4A, OGG, FLAC, WAV
- **Contrôles complets** : Lecture/Pause, précédent/suivant, avance/recule
- **Vitesses ajustables** : 0.5x à 2.0x par paliers de 0.1x
- **Chapitres** : Navigation fluide entre chapitres
- **Progression sauvegardée** : Reprise automatique où vous vous êtes arrêté

### 🌊 **Musiques d'Ambiance**
- **Bibliothèque intégrée** : 4 ambiances pré-packagées (feu de cheminée, pluie, forêt, café)
- **Import personnalisé** : Ajoutez vos propres musiques d'ambiance
- **Mixage indépendant** : Volumes séparés livre/ambiance
- **Boucle automatique** : Lecture continue des ambiances

### 🎨 **Interface Utilisateur**
- **Design Material** : Thème sombre élégant et moderne
- **Navigation intuitive** : Onglets principaux + tiroirs latéraux
- **Responsive** : Adaptation parfaite Android/iOS
- **Accessibilité** : Contrôles grands et contrastés élevés
- **Animations fluides** : Transitions et feedback visuels

---

## 🏗️ **Architecture Technique**

### **🛠️ Technologies**
- **Framework** : Flutter 3.0+ (Dart)
- **State Management** : Provider pattern
- **Base de données** : SQLite (sqflite)
- **Audio** : Just Audio + Audio Service
- **Réseau** : HTTP client avec cache intelligent
- **Stockage** : Système de fichiers local + SharedPreferences

### **🏛️ Architecture Clean**
```
lib/
├── models/          # Classes de données (Audiobook, LibrivoxBook, etc.)
├── providers/       # Gestion d'état (AudiobookProvider, PlayerProvider)
├── services/        # Logique métier (AudioPlayerService, LibrivoxService)
├── screens/         # Interfaces utilisateur
└── widgets/         # Composants réutilisables
```

### **📦 Packages Clés**
- **just_audio** : Lecteur audio multi-formats
- **audio_service** : Service audio en arrière-plan
- **sqflite** : Base de données SQLite locale
- **http** : Client HTTP avec cache
- **shared_preferences** : Stockage persistant clé-valeur
- **permission_handler** : Gestion des permissions Android/iOS

---

## 🚀 **Versions & Branches**

### **🌿 Branches Disponibles**
- **`main`** : Version stable de développement
- **`production`** : Version finale v1.0 prête pour production
- **`booktune`** : Ancienne branche d'améliorations (obsolète)

### **📈 Historique des Versions**

#### **v2.0 - Freemium (En développement)**
- ✅ Limitations intelligentes pour monétisation
- ✅ Catalogue premium partenaires (prochainement)
- ✅ Analytics et optimisation conversion

#### **v1.0 - Production (Actuelle)**
- ✅ Application complète et stable
- ✅ Catalogue LibriVox intégré
- ✅ Lecteur professionnel avec ambiances
- ✅ Bibliothèque personnelle avancée
- ✅ Interface Material Design

#### **v0.x - Développement**
- ✅ Import fichiers locaux
- ✅ Lecteur audio de base
- ✅ Musiques d'ambiance
- ✅ Text-to-Speech (TTS)

---

## 📊 **Statistiques du Projet**

- **📁 Codebase** : 45+ fichiers Dart, 5000+ lignes
- **🎯 Fonctionnalités** : 8 écrans, 12 services, 8 modèles
- **🔧 Technologies** : Flutter, SQLite, Audio Service
- **📱 Plateformes** : Android (priorité), iOS (compatible)
- **🌍 Langues** : Français/Anglais (interface), Multilingue (contenus)
- **💾 Données** : +15K livres LibriVox, ambiances intégrées

---

## 🛠️ **Installation & Développement**

### **📋 Prérequis**
- Flutter SDK 3.0+
- Android Studio ou VS Code
- Appareil Android/iOS pour tests

### **🚀 Démarrage Rapide**
```bash
# Cloner le repository
git clone https://github.com/Jean-bassene/booktune.git
cd booktune

# Basculer sur la branche production
git checkout production

# Installer les dépendances
flutter pub get

# Lancer en mode développement
flutter run
```

### **🧪 Tests**
```bash
# Tests unitaires
flutter test

# Tests d'intégration
flutter test integration_test/
```

### **📦 Build Production**
```bash
# Android APK
flutter build apk --release

# Android AAB (Play Store)
flutter build appbundle --release

# iOS (nécessite macOS)
flutter build ios --release
```

---

## 📈 **Roadmap & Améliorations Futures**

### **🔮 Prochaines Fonctionnalités**
- **🛒 Catalogues payants** : Intégration Audible, Google Play Books
- **🤝 Affiliations** : Programme de parrainage partenaires
- **📊 Analytics avancés** : Métriques d'écoute détaillées
- **🔄 Synchronisation** : Sauvegarde cross-device
- **🎯 Recommandations** : IA basée sur vos préférences

### **📱 Améliorations UI/UX**
- **🎨 Thèmes** : Mode clair/sombre, thèmes personnalisables
- **📱 Wear OS** : Contrôles sur montre connectée
- **🗣️ Assistant vocal** : Contrôles Google Assistant/Alexa
- **📊 Dashboard** : Statistiques personnelles d'écoute

---

## 🤝 **Contribution**

Les contributions sont les bienvenues ! Pour contribuer :

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/AmazingFeature`)
3. Commit vos changements (`git commit -m 'Add some AmazingFeature'`)
4. Push sur la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

---

## 📄 **Licence**

Ce projet est sous licence MIT - voir le fichier [LICENSE](LICENSE) pour plus de détails.

---

## 📞 **Contact & Support**

- **📧 Email** : [Votre email de contact]
- **🐛 Issues** : [GitHub Issues](https://github.com/Jean-bassene/booktune/issues)
- **📱 Démo** : Site web de présentation (bientôt disponible)

---

## 🙏 **Remerciements**

- **LibriVox** : Pour leur incroyable bibliothèque de livres audio gratuits
- **Flutter Community** : Pour les packages et le support exceptionnels
- **Open Source** : Pour les technologies qui rendent ce projet possible

---

**🎧 Découvrez une nouvelle façon d'écouter vos livres préférés avec BookTune !** ✨📚
