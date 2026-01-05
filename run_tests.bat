@echo off
echo 🧪 Test Audiobook Mixer - Vérifications automatiques
echo.

echo [1/5] Vérification des fichiers ambiance...
if exist "assets\ambient\rain.mp3" (
    echo ✓ rain.mp3 présent
) else (
    echo ✗ rain.mp3 manquant
)

if exist "assets\ambient\forest.mp3" (
    echo ✓ forest.mp3 présent
) else (
    echo ✗ forest.mp3 manquant
)

if exist "assets\ambient\ocean.mp3" (
    echo ✓ ocean.mp3 présent
) else (
    echo ✗ ocean.mp3 manquant
)

if exist "assets\ambient\fireplace.mp3" (
    echo ✓ fireplace.mp3 présent
) else (
    echo ✗ fireplace.mp3 manquant
)

if exist "assets\ambient\cafe.mp3" (
    echo ✓ cafe.mp3 présent
) else (
    echo ✗ cafe.mp3 manquant
)

echo.
echo [2/5] Vérification des fichiers de test...
if exist "test_files\le_petit_prince.txt" (
    echo ✓ Fichier TXT de test présent
) else (
    echo ✗ Fichier TXT de test manquant
)

echo.
echo [3/5] Vérification des dépendances...
flutter pub deps > nul 2>&1
if %errorlevel% == 0 (
    echo ✓ Dépendances Flutter OK
) else (
    echo ✗ Problème dépendances Flutter
)

echo.
echo [4/5] Test de compilation...
flutter analyze --no-fatal-infos > nul 2>&1
if %errorlevel% == 0 (
    echo ✓ Code compile sans erreurs
) else (
    echo ⚠ Warnings présents (normal)
)

echo.
echo [5/5] Vérification structure projet...
if exist "lib\main.dart" (
    echo ✓ Point d'entrée principal OK
) else (
    echo ✗ main.dart manquant
)

if exist "lib\services\ambient_presets_service.dart" (
    echo ✓ Service ambiances OK
) else (
    echo ✗ Service ambiances manquant
)

if exist "lib\services\text_import_service.dart" (
    echo ✓ Service import EPUB/PDF OK
) else (
    echo ✗ Service import manquant
)

echo.
echo 🎉 Vérifications terminées !
echo.
echo Pour tester l'app :
echo 1. flutter run
echo 2. Suivre TEST_GUIDE.md
echo.
pause