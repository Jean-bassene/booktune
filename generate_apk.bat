@echo off
echo ===========================================
echo  BOOKTUNE APK GENERATOR POUR APKPURE
echo ===========================================
echo.

echo Étape 1: Vérification des prérequis...
echo.

REM Vérifier si Flutter est installé
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter n'est pas installé ou n'est pas dans le PATH
    echo Téléchargez Flutter depuis https://flutter.dev
    pause
    exit /b 1
)
echo ✅ Flutter détecté

REM Vérifier si Java est installé
java -version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Java n'est pas installé ou n'est pas dans le PATH
    echo Téléchargez JDK depuis https://adoptium.net/
    pause
    exit /b 1
)
echo ✅ Java détecté

echo.
echo Étape 2: Génération du keystore de signature...
echo.

cd android\app

REM Générer le keystore si inexistant
if not exist "keystore.jks" (
    echo Génération du keystore...
    keytool -genkeypair -v -keystore keystore.jks -alias booktune -keyalg RSA -keysize 2048 -validity 10000 -storepass booktune2024 -keypass booktune2024 -dname "CN=BookTune, OU=BookTune, O=BookTune, L=Paris, ST=Ile-de-France, C=FR"
    if %errorlevel% neq 0 (
        echo ❌ Erreur lors de la génération du keystore
        echo Assurez-vous que Java JDK est installé et keytool est dans le PATH
        cd ..\..
        pause
        exit /b 1
    )
    echo ✅ Keystore généré avec succès
) else (
    echo ✅ Keystore déjà existant
)

cd ..\..

echo.
echo Étape 3: Nettoyage du cache Flutter...
echo.

flutter clean
if %errorlevel% neq 0 (
    echo ❌ Erreur lors du nettoyage
    pause
    exit /b 1
)
echo ✅ Cache nettoyé

echo.
echo Étape 4: Récupération des dépendances...
echo.

flutter pub get
if %errorlevel% neq 0 (
    echo ❌ Erreur lors de la récupération des dépendances
    pause
    exit /b 1
)
echo ✅ Dépendances récupérées

echo.
echo Étape 5: Génération de l'APK signé...
echo.

flutter build apk --release
if %errorlevel% neq 0 (
    echo ❌ Erreur lors de la génération de l'APK
    echo Vérifiez les logs ci-dessus pour les détails
    pause
    exit /b 1
)

echo.
echo ===========================================
echo  🎉 APK BOOKTUNE GÉNÉRÉ AVEC SUCCÈS ! 🎉
echo ===========================================
echo.

echo 📱 Fichier APK généré :
echo    build\app\outputs\flutter-apk\app-release.apk
echo.

echo 📦 Informations de l'APK :
powershell "Get-Item build\app\outputs\flutter-apk\app-release.apk | Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize"
echo.

echo 🔐 Signature de l'APK :
echo    Package Name: com.booktune.app
echo    Alias: booktune
echo    Validité: 10,000 jours
echo.

echo 📤 Pour soumettre sur ApkPure :
echo    1. Allez sur https://apkpure.com/
echo    2. Cliquez sur "Submit App"
echo    3. Téléversez le fichier app-release.apk
echo    4. Remplissez les informations demandées
echo    5. Assurez-vous que le nom du package correspond
echo.

echo ✅ APK prêt pour ApkPure !
echo.

pause
