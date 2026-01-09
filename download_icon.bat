@echo off
echo ========================================
echo Téléchargement de l'icône de l'app...
echo ========================================

REM URL de l'image (livre avec logo BookTune)
set "url=https://minimax-algeng-chat-tts-us.oss-us-east-1.aliyuncs.com/ccv2%2F2026-01-09%2FMiniMax-M2.1%2F1982827895197799239%2F7c3aee8c18c2e567b7248d511280ab550f7a2a099625c7f317915cb88cc45856..png"

REM Créer le dossier assets/images
mkdir assets\images 2>nul

REM Essayer de télécharger avec PowerShell
powershell -Command "Invoke-WebRequest -Uri '%url%' -OutFile 'assets/images/app_icon.png' -TimeoutSec 30"

if exist "assets/images/app_icon.png" (
    echo.
    echo Icône téléchargée avec succès!
    echo Fichier: assets/images/app_icon.png
    for %%I in (assets/images/app_icon.png) do echo Taille: %%~zI bytes
    echo.
) else (
    echo.
    echo Erreur: Le téléchargement a échoué.
    echo.
    echo Veuillez télécharger manuellement l'image depuis:
    echo %url%
    echo Et la sauvegarder dans: assets/images/app_icon.png
    echo.
)

echo ========================================
echo Génération des icônes...
echo ========================================
echo.
echo Exécutez cette commande pour générer les icônes:
echo   flutter pub run flutter_launcher_icons
echo.
echo Ou reconstruisez l'app avec:
echo   flutter build apk --release
echo.
pause
