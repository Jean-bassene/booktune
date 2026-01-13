@echo off
echo ===========================================
echo  CRÉATION KEYSTORE POUR BOOKTUNE
echo ===========================================
echo.

echo Recherche du JDK installé...

REM Recherche de Java dans le registre Windows
for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\JavaSoft\Java Development Kit" /v CurrentVersion 2^>nul') do set JDK_VERSION=%%b

if defined JDK_VERSION (
    echo JDK trouvé dans le registre: %JDK_VERSION%

    REM Recherche du chemin d'installation du JDK
    for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\JavaSoft\Java Development Kit\%JDK_VERSION%" /v JavaHome 2^>nul') do set JAVA_HOME=%%b

    if defined JAVA_HOME (
        echo JAVA_HOME trouvé: %JAVA_HOME%
        set KEYTOOL="%JAVA_HOME%\bin\keytool.exe"
        goto :create_keystore
    )
)

REM Recherche alternative dans les chemins communs
echo Recherche dans les chemins communs...
set KEYTOOL="C:\Program Files\Java\jdk*\bin\keytool.exe"
if exist %KEYTOOL% goto :create_keystore

set KEYTOOL="C:\Program Files (x86)\Java\jdk*\bin\keytool.exe"
if exist %KEYTOOL% goto :create_keystore

REM Recherche via where
for /f "delims=" %%i in ('where keytool 2^>nul') do set KEYTOOL="%%i"
if defined KEYTOOL goto :create_keystore

echo ❌ Keytool introuvable
echo Veuillez installer JDK depuis https://adoptium.net/
pause
exit /b 1

:create_keystore
echo ✅ Keytool trouvé: %KEYTOOL%
echo.
echo Création du keystore de production...

%KEYTOOL% -genkeypair -v -keystore "android\app\keystore_production.jks" -alias booktune_release -keyalg RSA -keysize 2048 -validity 10000 -storepass BookTune2024Production -keypass BookTune2024Production -dname "CN=BookTune App, OU=BookTune, O=BookTune, L=Paris, ST=Ile-de-France, C=FR" -noprompt

if %errorlevel% equ 0 (
    echo.
    echo ===========================================
    echo  ✅ KEYSTORE CRÉÉ AVEC SUCCÈS !
    echo ===========================================
    echo.
    echo 📁 keystore_production.jks créé dans android/app/
    echo 🔑 Alias: booktune_release
    echo 🔒 Password: BookTune2024Production
    echo.
    echo Prochaine étape: Générer l'APK avec flutter build apk --release
) else (
    echo.
    echo ❌ Erreur lors de la création du keystore
    echo Code d'erreur: %errorlevel%
    pause
    exit /b 1
)

echo.
pause
