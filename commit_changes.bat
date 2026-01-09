@echo off
echo ========================================
echo Commit des changements sur booktune
echo ========================================

cd /d "%~dp0"

echo Ajout des fichiers...
git add lib/ pubspec.yaml download_icon.bat setup_icon.ps1

echo Commit...
git commit -m "feat: LibriVox search by author + chapter auto-play + author display

- Recherche par auteur avec API LibriVox /search/?author=query
- Correction lecture auto des chapitres avec flag anti-concurrent
- Affichage correct du titre et auteur du livre LibriVox
- Configuration flutter_launcher_icons pour l'icone de l'app"

echo.
echo Push vers GitHub...
git push origin booktune

echo.
echo ========================================
echo Création de la nouvelle branche booktune2
echo ========================================

git checkout -b booktune2

echo.
echo ========================================
echo Terminé!
echo Branche actuelle: booktune2
echo ========================================
pause
