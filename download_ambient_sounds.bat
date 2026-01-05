@echo off
echo Téléchargement des sons d'ambiance gratuits...
echo.

REM Créer le dossier s'il n'existe pas
if not exist "assets\ambient" mkdir "assets\ambient"

echo [1/5] Téléchargement pluie douce...
curl -L "https://www.soundjay.com/misc/sounds/rain-01.wav" -o "assets\ambient\rain_temp.wav" 2>nul
if exist "assets\ambient\rain_temp.wav" (
    echo ✓ Pluie téléchargée
) else (
    echo ✗ Échec pluie - utilisation de sons alternatifs
)

echo [2/5] Téléchargement forêt...
curl -L "https://www.soundjay.com/nature/sounds/forest-1.wav" -o "assets\ambient\forest_temp.wav" 2>nul
if exist "assets\ambient\forest_temp.wav" (
    echo ✓ Forêt téléchargée
) else (
    echo ✗ Échec forêt
)

echo [3/5] Téléchargement océan...
curl -L "https://www.soundjay.com/nature/sounds/ocean-1.wav" -o "assets\ambient\ocean_temp.wav" 2>nul
if exist "assets\ambient\ocean_temp.wav" (
    echo ✓ Océan téléchargé
) else (
    echo ✗ Échec océan
)

echo [4/5] Téléchargement feu de cheminée...
curl -L "https://www.soundjay.com/misc/sounds/fireplace-1.wav" -o "assets\ambient\fireplace_temp.wav" 2>nul
if exist "assets\ambient\fireplace_temp.wav" (
    echo ✓ Cheminée téléchargée
) else (
    echo ✗ Échec cheminée
)

echo [5/5] Téléchargement café...
curl -L "https://www.soundjay.com/misc/sounds/coffee-shop-1.wav" -o "assets\ambient\cafe_temp.wav" 2>nul
if exist "assets\ambient\cafe_temp.wav" (
    echo ✓ Café téléchargé
) else (
    echo ✗ Échec café
)

echo.
echo Conversion en MP3 (si FFmpeg disponible)...
where ffmpeg >nul 2>nul
if %errorlevel% == 0 (
    echo FFmpeg trouvé - conversion en cours...
    for %%f in (assets\ambient\*_temp.wav) do (
        ffmpeg -i "%%f" -acodec mp3 -ab 128k "%%~nf.mp3" -y 2>nul
        del "%%f"
    )
    echo ✓ Conversion terminée
) else (
    echo ⚠ FFmpeg non trouvé - fichiers WAV conservés
    echo Installez FFmpeg pour la conversion automatique
    ren "assets\ambient\rain_temp.wav" "rain.wav" 2>nul
    ren "assets\ambient\forest_temp.wav" "forest.wav" 2>nul
    ren "assets\ambient\ocean_temp.wav" "ocean.wav" 2>nul
    ren "assets\ambient\fireplace_temp.wav" "fireplace.wav" 2>nul
    ren "assets\ambient\cafe_temp.wav" "cafe.wav" 2>nul
)

echo.
echo ✅ Téléchargement terminé !
echo Les fichiers sont dans assets\ambient\
echo.
pause