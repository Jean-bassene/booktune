# Script pour télécharger des musiques d'ambiance gratuites
# Sources: Bensound.com et Incompetech.com

param(
    [string]$OutputDir = "assets\ambient"
)

Write-Host "🎵 Téléchargement de musiques d'ambiance gratuites..." -ForegroundColor Green
Write-Host "Dossier de destination: $OutputDir" -ForegroundColor Yellow
Write-Host ""

# Créer le dossier s'il n'existe pas
if (!(Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
    Write-Host "✅ Dossier créé: $OutputDir" -ForegroundColor Green
}

Write-Host "📋 Musiques disponibles gratuitement :" -ForegroundColor Cyan
Write-Host "1. Bensound.com - Musique gratuite pour projets personnels" -ForegroundColor White
Write-Host "   • Little Planet (instrumental relaxant)" -ForegroundColor Gray
Write-Host "   • The Lounge (piano apaisant)" -ForegroundColor Gray
Write-Host "   • Creative Minds (ambiance douce)" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Incompetech.com - Kevin MacLeod (Creative Commons)" -ForegroundColor White
Write-Host "   • Floating Cities (ambiance spatiale)" -ForegroundColor Gray
Write-Host "   • Impact Moderato (musique motivante)" -ForegroundColor Gray
Write-Host ""

Write-Host "🔗 Liens de téléchargement :" -ForegroundColor Yellow
Write-Host "Bensound: https://www.bensound.com/free-music-for-videos" -ForegroundColor Blue
Write-Host "Incompetech: https://incompetech.com/music/royalty-free/music.html" -ForegroundColor Blue
Write-Host "Freesound: https://freesound.org/search/?q=rain+forest" -ForegroundColor Blue
Write-Host ""

Write-Host "📝 Instructions :" -ForegroundColor Green
Write-Host "1. Visitez les sites ci-dessus" -ForegroundColor White
Write-Host "2. Téléchargez les fichiers MP3 qui vous plaisent" -ForegroundColor White
Write-Host "3. Renommez-les simplement (ex: rain.mp3, forest.mp3, piano.mp3, sunrise.mp3)" -ForegroundColor White
Write-Host "4. Placez-les dans le dossier $OutputDir" -ForegroundColor White
Write-Host "5. Modifiez ambient_presets_service.dart pour les référencer" -ForegroundColor White
Write-Host ""

Write-Host "⚠️  Important: Vérifiez toujours les licences avant utilisation !" -ForegroundColor Red
Write-Host ""

# Vérifier les fichiers existants
Write-Host "📁 Fichiers actuellement dans $OutputDir :" -ForegroundColor Cyan
if (Test-Path $OutputDir) {
    $files = Get-ChildItem $OutputDir -Filter "*.mp3"
    if ($files.Count -eq 0) {
        Write-Host "   Aucun fichier MP3 trouvé" -ForegroundColor Yellow
    } else {
        foreach ($file in $files) {
            $size = [math]::Round($file.Length / 1MB, 2)
            Write-Host "   $($file.Name) ($size MB)" -ForegroundColor White
        }
    }
}

Write-Host ""
Write-Host "🎯 Exemple de configuration dans ambient_presets_service.dart :" -ForegroundColor Magenta
Write-Host '{
  '\''name'\'': '\''Pluie Relaxante'\'',
  '\''filePath'\'': '\''assets/ambient/rain.mp3'\'',
  '\''category'\'': '\''nature'\'',
  '\''duration'\'': 180,
  '\''description'\'': '\''Sons de pluie apaisants'\''
},' -ForegroundColor Gray

Write-Host ""
Read-Host "Appuyez sur Entrée pour quitter"