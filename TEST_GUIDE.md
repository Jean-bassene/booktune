# 🧪 Guide de Test - Audiobook Mixer

## Tests à effectuer

### 1. Test des Ambiances Pré-packagées ✅
- Ouvrir l'app → Onglet "Lecteur" 
- Cliquer "Presets" → Sélectionner une ambiance
- Vérifier que l'ambiance se lance et boucle

### 2. Test Import TXT ✅
- Onglet "Importer" → "Importer TXT/EPUB/PDF"
- Sélectionner `test_files/le_petit_prince.txt`
- Vérifier import réussi + message de succès
- Vérifier que le livre apparaît dans la liste

### 3. Test TTS + Ambiance ✅
- Sélectionner le livre importé → "Lire"
- Aller dans "Lecteur" → Choisir une ambiance
- Vérifier que TTS + ambiance jouent ensemble
- Tester les contrôles volume séparés

### 4. Test Contrôles Avancés ✅
- **Vitesse** : Tester 1x, 1.25x, 1.5x, 2x
- **Timer sommeil** : Définir 5min, vérifier countdown
- **Skip** : Avancer/reculer 15s
- **Pause/Play** : Vérifier synchronisation TTS+ambiance

### 5. Test Sauvegarde Position ✅
- Lire un livre, faire pause
- Fermer/rouvrir l'app
- Vérifier reprise à la bonne position

## Fichiers de test disponibles

### TXT
- `test_files/le_petit_prince.txt` - Texte français classique

### Pour tester EPUB/PDF
- Télécharger un EPUB gratuit depuis Project Gutenberg
- Ou utiliser un PDF simple

## Résultats attendus

✅ **Ambiances** : 5 presets fonctionnels avec boucle
✅ **Import TXT** : Extraction titre/auteur automatique  
✅ **TTS** : Lecture française claire et fluide
✅ **Mixage** : Audio livre + ambiance simultanés
✅ **Contrôles** : Tous les boutons réactifs
✅ **Persistance** : Position sauvegardée automatiquement

## En cas de problème

1. **TTS ne fonctionne pas** → Vérifier paramètres langue Android
2. **Ambiances silencieuses** → Vérifier volume ambiance > 0
3. **Import échoue** → Vérifier format fichier supporté
4. **App crash** → Consulter logs Flutter DevTools

## Prochains tests (optionnels)

- Test avec gros fichiers EPUB (>1MB)
- Test avec PDF complexe (images, tableaux)
- Test performance avec lecture longue (>1h)
- Test multitâche (appels, notifications)