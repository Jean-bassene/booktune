# 🔐 GUIDE RÉSOLUTION SIGNATURE APKPURE

## 🎯 Problème Identifié

Le message d'erreur **"La version que vous avez téléchargée n'a pas passé la vérification. Veuillez vérifier si le nom du package ou la signature correspondant"** indique un problème de cohérence de signature entre les soumissions précédentes et actuelles.

---

## 🔍 Diagnostic du Problème

### Possibles Causes :

1. **Changement de nom de package** : L'application a été renommée de `com.example.audiobook_mixer1` à `com.booktune.app`
2. **Changement de signature** : Nouvelle keystore ou paramètres différents
3. **Signature debug vs release** : Utilisation de clés de développement au lieu de production

---

## ✅ Solution Complète

### Étape 1 : Vérification du Nom du Package

**Nom actuel configuré :** `com.booktune.app`

Vérifiez dans `android/app/build.gradle.kts` :
```kotlin
defaultConfig {
    applicationId = "com.booktune.app"  // ✅ Doit être identique
}
```

### Étape 2 : Configuration de Signature Cohérente

**Keystore créé avec ces paramètres :**
- Alias : `booktune`
- Store Password : `booktune2024`
- Key Password : `booktune2024`
- Validité : 10,000 jours

### Étape 3 : Génération de l'APK

Utilisez le script fourni `generate_apk.bat` :
```cmd
# Double-cliquez sur generate_apk.bat
# ou exécutez dans un terminal :
generate_apk.bat
```

---

## 📋 Checklist Avant Soumission

### ✅ Configuration Android :
- [ ] `applicationId = "com.booktune.app"` dans build.gradle.kts
- [ ] Keystore `keystore.jks` présent dans `android/app/`
- [ ] Configuration de signature release active
- [ ] Build release réussi sans erreur

### ✅ APK Généré :
- [ ] Fichier `build/app/outputs/flutter-apk/app-release.apk` existe
- [ ] Taille raisonnable (environ 50-80 MB pour une app Flutter)
- [ ] APK signé correctement (vérifiable avec `apksigner`)

### ✅ Vérification Signature :
```bash
# Vérifier la signature de l'APK
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
```

**Résultat attendu :**
```
Signer #1 certificate DN: CN=BookTune, OU=BookTune, O=BookTune, L=Paris, ST=Ile-de-France, C=FR
Signer #1 certificate SHA-256 digest: [hash]
Signer #1 certificate SHA-1 digest: [hash]
```

---

## 🛠️ Commandes de Diagnostic

### Vérifier les informations de l'APK :
```bash
# Informations générales
aapt dump badging build/app/outputs/flutter-apk/app-release.apk

# Package name et version
aapt dump badging build/app/outputs/flutter-apk/app-release.apk | findstr "package:"
```

### Vérifier la signature :
```bash
# Méthode 1 : apksigner (recommandé)
apksigner verify build/app/outputs/flutter-apk/app-release.apk

# Méthode 2 : jarsigner
jarsigner -verify -verbose build/app/outputs/flutter-apk/app-release.apk
```

---

## 🚨 Solutions par Problème

### **Problème : "Package name mismatch"**

**Cause :** Nom du package différent entre soumissions
**Solution :**
1. Vérifiez `applicationId` dans build.gradle.kts
2. Assurez-vous qu'il correspond exactement à la soumission précédente
3. Si changement nécessaire, contactez ApkPure pour changement de package

### **Problème : "Signature verification failed"**

**Cause :** Signature différente ou corrompue
**Solution :**
1. Supprimez l'ancien keystore : `del android\app\keystore.jks`
2. Régénérez avec le script : `generate_apk.bat`
3. Vérifiez que les mots de passe sont corrects

### **Problème : "Certificate changed"**

**Cause :** Nouveau certificat de signature
**Solution :**
1. Contactez ApkPure support pour autoriser le changement
2. Fournissez les détails du nouveau certificat
3. Attendez validation (24-48h)

---

## 📝 Procédure de Soumission ApkPure

### Étape 1 : Préparation
1. **APK signé** généré avec `generate_apk.bat`
2. **Captures d'écran** : 6-8 images (1080x1920)
3. **Description** : Française et anglaise
4. **Icône** : 512x512 PNG
5. **Informations** : Catégorie, tags, classification

### Étape 2 : Soumission
1. Allez sur https://apkpure.com/publish
2. Connectez-vous ou créez un compte
3. Cliquez "Submit New App"
4. Téléversez l'APK `app-release.apk`
5. Remplissez les métadonnées

### Étape 3 : Métadonnées
```
Titre : BookTune - Lecteur Audio Révolutionnaire
Description courte : Découvrez +15K livres audio gratuits avec ambiances
Catégorie : Music & Audio
Tags : audiobook, audio, livre, lecture, offline, musique
Classification : Tout public (PEGI 3)
```

### Étape 4 : Validation
- **Vérification automatique** : 5-15 minutes
- **Review manuelle** : 24-48h si nécessaire
- **Publication** : Automatique après approbation

---

## 🔧 Outils de Dépannage

### Script de vérification APK :
```batch
@echo off
echo Vérification APK BookTune...
echo.

echo 1. Informations générales :
aapt dump badging build\app\outputs\flutter-apk\app-release.apk | findstr "package:"
echo.

echo 2. Vérification signature :
apksigner verify build\app\outputs\flutter-apk\app-release.apk
if %errorlevel% equ 0 (
    echo ✅ Signature valide
) else (
    echo ❌ Signature invalide
)
echo.

echo 3. Empreintes certificat :
apksigner verify --print-certs build\app\outputs\flutter-apk\app-release.apk
echo.

pause
```

### Vérification keystore :
```bash
# Lister le contenu du keystore
keytool -list -v -keystore android/app/keystore.jks -storepass booktune2024
```

---

## 📞 Support ApkPure

Si les problèmes persistent :
- **Email support** : Contact@apkpure.com
- **Sujet** : "Signature Verification Issue - BookTune App"
- **Informations à fournir** :
  - Nom du package : `com.booktune.app`
  - Empreinte SHA-256 du certificat
  - Logs d'erreur complets

---

## ✅ Checklist Finale

Avant soumission :
- [ ] APK généré avec `generate_apk.bat`
- [ ] Signature vérifiée avec `apksigner verify`
- [ ] Package name cohérent : `com.booktune.app`
- [ ] Métadonnées préparées (description, screenshots)
- [ ] Compte ApkPure créé et validé

**APK prêt pour une soumission réussie sur ApkPure !** 🚀📱
