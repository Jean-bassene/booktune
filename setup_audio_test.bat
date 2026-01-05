@echo off
REM Script simple pour tester l'app avec un fichier audio

setlocal enabledelayedexpansion

echo.
echo === Setup Audio Test - Version Simple ===
echo.

REM Vérifier ffmpeg
where ffmpeg >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERREUR] ffmpeg non trouvé!
    echo Installez avec: choco install ffmpeg -y
    exit /b 1
)

echo [OK] ffmpeg disponible

REM Créer le dossier Music
echo [INFO] Création du dossier Music dans l'emulateur...
adb shell mkdir -p /storage/emulated/0/Music

REM Générer un fichier audio test de 10 secondes
set TEMP_DIR=%TEMP%\audiobook_test
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"
set AUDIO_FILE=%TEMP_DIR%\test_audio.mp3

echo [INFO] Génération du fichier audio (10 secondes)...
ffmpeg -f lavfi -i "sine=frequency=440:duration=10" -q:a 9 -acodec libmp3lame -ab 128k "%AUDIO_FILE%" -y >nul 2>&1

if exist "%AUDIO_FILE%" (
    echo [OK] Fichier créé: %AUDIO_FILE%
) else (
    echo [ERREUR] Impossible de créer le fichier audio!
    exit /b 1
)

REM Pousser vers l'emulateur
echo [INFO] Envoi du fichier vers l'emulateur...
adb push "%AUDIO_FILE%" /storage/emulated/0/Music/test_audiobook.mp3

echo [OK] Fichier dans l'emulateur!
echo.
echo [INFO] Fichiers disponibles:
adb shell ls /storage/emulated/0/Music/
echo.

REM Lancer Flutter
echo [INFO] Lancement de Flutter...
cd /d c:\Projets\audiobook_mixer1
flutter run

REM Cleanup
echo [INFO] Nettoyage...
rmdir /s /q "%TEMP_DIR%" 2>nul

echo [OK] Fini!
