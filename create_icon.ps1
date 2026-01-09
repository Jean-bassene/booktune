# Script pour créer une icône par défaut pour BookTune

$outputPath = "assets\images\app_icon.png"

# Vérifier si le dossier existe
if (!(Test-Path "assets\images")) {
    New-Item -ItemType Directory -Force -Path "assets\images" | Out-Null
    Write-Host "Dossier assets/images créé"
}

# Créer une icône simple avec Canvas (si PowerShell moderne)
# Sinon, afficher les instructions manuelles

Write-Host ""
Write-Host "======================================="
Write-Host "Création de l'icône BookTune"
Write-Host "======================================="
Write-Host ""

# Essayer de créer une icône PNG basique
try {
    # Créer une image 512x512 avec un fond violet et un livre
    Add-Type -AssemblyName System.Drawing
    
    $bitmap = New-Object System.Drawing.Bitmap(512, 512)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    
    # Fond violet
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(103, 0, 186)) # Purple
    $graphics.FillRectangle($brush, 0, 0, 512, 512)
    
    # Dessiner un livre (rectangle blanc avec dos)
    $bookBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $graphics.FillRectangle($bookBrush, 120, 80, 272, 352)
    
    # Dos du livre (plus foncé)
    $spineBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(80, 0, 150))
    $graphics.FillRectangle($spineBrush, 120, 80, 40, 352)
    
    # Texte "B" pour BookTune
    $font = New-Object System.Drawing.Font("Arial", 200, [System.Drawing.FontStyle]::Bold)
    $brushText = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(103, 0, 186))
    $point = New-Object System.Drawing.PointF(200, 120)
    $graphics.DrawString("B", $font, $brushText, $point)
    
    # Sauvegarder
    $bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    
    Write-Host "Icône créée : $outputPath"
    Write-Host "Taille: 512x512 pixels"
    
    $bitmap.Dispose()
    $graphics.Dispose()
} catch {
    Write-Host "Impossible de créer l'icône automatiquement."
    Write-Host ""
    Write-Host "Veuillez créer manuellement :"
    Write-Host "1. Créez une image 512x512 pixels"
    Write-Host "2. Dessinez un livre avec le logo BookTune"
    Write-Host "3. Sauvegardez sous : $outputPath"
    Write-Host ""
    Write-Host "Ou utilisez un outil en ligne comme canva.com"
}

Write-Host ""
Write-Host "Ensuite, exécutez :"
Write-Host "  dart run flutter_launcher_icons"
Write-Host ""
