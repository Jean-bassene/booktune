# Guide BookTune - Icônes et Musiques d'Ambiance

## 🎵 Musiques d'Ambiance Gratuites et Libres de Droits

Voici 4 excellentes sources de musique d'ambiance gratuite et légale :

### 🌧️ **Pluie/Orage** - Sons Naturels
- **Source** : Freesound.org
- **Recherche** : "rain" ou "thunderstorm"
- **Durée suggérée** : 2-3 minutes en boucle
- **Exemple** : Sons de pluie naturelle sans musique

### 🌿 **Forêt Paisible** - Ambiance Nature
- **Source** : Bensound.com (gratuit)
- **Morceau** : "Little Planet" ou "Creative Minds"
- **Style** : Instrumental relaxant, parfait pour la lecture
- **Licence** : Gratuit pour usage personnel

### 🌅 **Aube/Éveil** - Musique Inspirante
- **Source** : Incompetech.com (Kevin MacLeod)
- **Morceau** : "Floating Cities" ou "Impact Moderato"
- **Style** : Classique moderne, motivant
- **Licence** : Creative Commons (gratuit)

### 🎹 **Piano Apaisant** - Musique Douce
- **Source** : Bensound.com (gratuit)
- **Morceau** : "The Lounge" ou "Slow Motion"
- **Style** : Piano solo, très relaxant
- **Licence** : Gratuit pour usage personnel

### 📥 Comment Télécharger et Intégrer

1. **Visitez les sites** mentionnés ci-dessus
2. **Téléchargez** les fichiers MP3 (format recommandé)
3. **Renommez** les fichiers selon vos préférences :
   - `rain.mp3`
   - `forest.mp3`
   - `sunrise.mp3`
   - `piano.mp3`
4. **Placez-les** dans `assets/ambient/`
5. **Mettez à jour** `lib/services/ambient_presets_service.dart`

## 🎨 Icônes de l'App

### Icônes Générées Automatiquement
- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` (48x48)
- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` (72x72)
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` (96x96)
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` (144x144)
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` (192x192)

### Pour Changer l'Icône Principale
1. Placez votre image dans `assets/images/app_icon.png` (1024x1024px recommandé)
2. Exécutez : `python generate_icon.py`
3. Toutes les icônes seront automatiquement générées

### Sources d'Icônes
- **iOS** : `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- **Web** : `web/icons/Icon-192.png` et `Icon-512.png`

Ces fichiers sont générés automatiquement par le script Python.
