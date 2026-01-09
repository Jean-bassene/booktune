# Comment mettre à jour l'icône de l'app BookTune

## Les icônes actuelles

Les icônes sont situées dans :
- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` (48x48)
- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` (72x72)
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` (96x96)
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` (144x144)
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` (192x192)

## Pour remplacer par ta nouvelle image (livre + BookTune)

### Option 1 : Manuelle (avec Paint ou autre)

1. **Télécharge l'image** depuis :
   https://minimax-algeng-chat-tts-us.oss-us-east-1.aliyuncs.com/ccv2%2F2026-01-09%2FMiniMax-M2.1%2F1982827895197799239%2F7c3aee8c18c2e567b7248d511280ab550f7a2a099625c7f317915cb88cc45856..png

2. **Redimensionne** aux 5 tailles ci-dessus avec Paint, GIMP, ou un outil en ligne

3. **Remplace** les fichiers dans les dossiers `mipmap-*/`

### Option 2 : Automatique avec flutter_launcher_icons

1. Crée le dossier : `assets/images/`

2. Sauvegarde l'image sous : `assets/images/app_icon.png`
   (Utilise une image d'au moins 1024x1024 px pour la meilleure qualité)

3. Exécute :
   ```bash
   flutter pub run flutter_launcher_icons
   ```

4. Rebuild l'app :
   ```bash
   flutter build apk --release
   ```

## Sources de l'icône

- **iOS** : `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- **Web** : `web/icons/Icon-192.png` et `Icon-512.png`

Ces fichiers sont aussi générés par `flutter_launcher_icons`.
