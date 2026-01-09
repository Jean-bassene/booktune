# Script pour télécharger l'icône et configurer les icônes de l'app

$url = "https://minimax-algeng-chat-tts-us.oss-us-east-1.aliyuncs.com/ccv2%2F2026-01-09%2FMiniMax-M2.1%2F1982827895197799239%2F7c3aee8c18c2e567b7248d511280ab550f7a2a099625c7f317915cb88cc45856..png?Expires=1768053617&OSSAccessKeyId=LTAI5tCpJNKCf5EkQHSuL9xg&Signature=LOe4AH5BYV73upq0SkYae5386uE%3D"
$outputPath = "assets\images\app_icon_original.png"

Write-Host "Téléchargement de l'icône..."
Invoke-WebRequest -Uri $url -OutFile $outputPath

Write-Host "Icône téléchargée vers $outputPath"

# Créer les dossiers pour les différentes densités
$densities = @("mipmap-mdpi", "mipmap-hdpi", "mipmap-xhdpi", "mipmap-xxhdpi", "mipmap-xxxhdpi")
$sizes = @("48", "72", "96", "144", "192")

foreach ($density in $densities) {
    $dir = "android\app\src\main\res\$density"
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
}

Write-Host "Icône prête à être copiée dans les dossiers mipmap"
Write-Host ""
Write-Host "Pour générer les icônes aux bonnes tailles, utilise un outil comme:"
Write-Host "- Flutter Launcher Icons: flutter pub global activate flutter_launcher_icons"
Write-Host "- Ou un éditeur d'images pour redimensionner l'icône originale"
