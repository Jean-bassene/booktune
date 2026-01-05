param(
    [string]$DeviceId = "emulator-5554",
    [string]$Duration = 10,
    [string]$AudioName = "test_audiobook.mp3"
)

Write-Host "Setup Audio Test pour Emulateur" -ForegroundColor Cyan
Write-Host ""

# Verifier ffmpeg
$ffmpegPath = (Get-Command ffmpeg -ErrorAction SilentlyContinue).Source
if (-not $ffmpegPath) {
    Write-Host "ffmpeg non trouve. Installez avec: choco install ffmpeg -y" -ForegroundColor Red
    exit 1
}

Write-Host "ffmpeg trouve: OK" -ForegroundColor Green

# Creer dossier temp
$tempDir = "$env:TEMP\audiobook_test"
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir | Out-Null
}

$audioFile = Join-Path $tempDir $AudioName

# Generer fichier audio
Write-Host "Generation du fichier audio ($Duration secondes)..." -ForegroundColor Cyan

$cmd = "ffmpeg -f lavfi -i `"sine=frequency=440:duration=$Duration`" -q:a 9 -acodec libmp3lame -ab 128k `"$audioFile`" -y"
Invoke-Expression $cmd 2>&1 | Out-Null

if (Test-Path $audioFile) {
    Write-Host "Fichier audio cree: OK" -ForegroundColor Green
} else {
    Write-Host "Erreur creation fichier audio!" -ForegroundColor Red
    exit 1
}

# Verifier ADB
Write-Host ""
Write-Host "Verification ADB..." -ForegroundColor Cyan
$adbPath = (Get-Command adb -ErrorAction SilentlyContinue).Source
if (-not $adbPath) {
    Write-Host "adb non trouve!" -ForegroundColor Red
    exit 1
}

Write-Host "adb trouve: OK" -ForegroundColor Green

# Lister appareils
Write-Host ""
Write-Host "Appareils connectes:" -ForegroundColor Cyan
& adb devices

# Pousser audio
Write-Host ""
Write-Host "Envoi du fichier audio..." -ForegroundColor Cyan

$musicPath = "/storage/emulated/0/Music"
& adb -s $DeviceId shell mkdir -p $musicPath 2>&1 | Out-Null
& adb -s $DeviceId push $audioFile "$musicPath/$AudioName" 2>&1

Write-Host "Fichier pousse: OK" -ForegroundColor Green

# Lancer Flutter
Write-Host ""
Write-Host "Lancement de Flutter..." -ForegroundColor Cyan
Write-Host ""

& flutter run -d $DeviceId

# Cleanup
Write-Host ""
Write-Host "Nettoyage..." -ForegroundColor Cyan
Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Fait!" -ForegroundColor Green
