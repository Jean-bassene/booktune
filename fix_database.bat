@echo off
echo 🔧 Réparation de la base de données Booktune...
echo.

REM Vérifier si Flutter est installé
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter n'est pas installé ou n'est pas dans le PATH
    echo Veuillez installer Flutter depuis https://flutter.dev
    pause
    exit /b 1
)

echo 📱 Exécution du script de réparation...
flutter run fix_database.dart

if %errorlevel% equ 0 (
    echo.
    echo ✅ Base de données réparée avec succès !
    echo Vous pouvez maintenant relancer l'application Booktune.
) else (
    echo.
    echo ❌ Erreur lors de la réparation de la base de données
    echo Code d'erreur: %errorlevel%
)

echo.
pause