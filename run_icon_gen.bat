@echo off
echo ========================================
echo Génération de l'icône BookTune
echo ========================================

REM Créer le dossier si nécessaire
if not exist "assets\images" mkdir "assets\images"

REM Installer pillow si nécessaire
echo.
echo Vérification de Pillow (PIL)...
pip show pillow >nul 2>&1
if errorlevel 1 (
    echo Installation de Pillow...
    pip install pillow
)

echo.
echo Génération de l'icône...
python generate_icon.py

echo.
echo ========================================
echo Exécution de flutter_launcher_icons...
echo ========================================
dart run flutter_launcher_icons

echo.
echo ========================================
echo Terminé!
echo ========================================
pause
