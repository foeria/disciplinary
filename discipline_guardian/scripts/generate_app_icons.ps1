param(
    [string]$SourcePath = "web/icon.png",
    [double]$IconScale = 0.92
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Resolve-IconPath {
    param([string]$PathValue)

    if ([System.IO.Path]::IsPathRooted($PathValue)) {
        return (Resolve-Path $PathValue).Path
    }

    $projectRelativePath = Join-Path $projectRoot $PathValue
    if (Test-Path $projectRelativePath) {
        return (Resolve-Path $projectRelativePath).Path
    }

    return (Resolve-Path $PathValue).Path
}

$resolvedSourcePath = Resolve-IconPath -PathValue $SourcePath
$sourceBitmap = [System.Drawing.Bitmap]::FromFile($resolvedSourcePath)

function New-ResizedBitmap {
    param(
        [int]$Size,
        [double]$Scale
    )

    $bitmap = New-Object System.Drawing.Bitmap($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)

    try {
        $graphics.Clear([System.Drawing.Color]::Transparent)
        $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

        $drawSize = [Math]::Max(1, [int][Math]::Round($Size * $Scale))
        $offset = [int][Math]::Floor(($Size - $drawSize) / 2)
        $graphics.DrawImage($sourceBitmap, $offset, $offset, $drawSize, $drawSize)
    } finally {
        $graphics.Dispose()
    }

    return $bitmap
}

function Save-PngIcon {
    param(
        [string]$RelativePath,
        [int]$Size,
        [double]$Scale = $IconScale
    )

    $targetPath = Join-Path $projectRoot $RelativePath
    $targetDirectory = Split-Path -Parent $targetPath
    if (-not (Test-Path $targetDirectory)) {
        New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
    }

    $bitmap = New-ResizedBitmap -Size $Size -Scale $Scale
    try {
        $bitmap.Save($targetPath, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $bitmap.Dispose()
    }
}

function Get-PngBytes {
    param(
        [int]$Size,
        [double]$Scale = $IconScale
    )

    $bitmap = New-ResizedBitmap -Size $Size -Scale $Scale
    $memoryStream = New-Object System.IO.MemoryStream

    try {
        $bitmap.Save($memoryStream, [System.Drawing.Imaging.ImageFormat]::Png)
        [byte[]]$bytes = $memoryStream.ToArray()
        return ,$bytes
    } finally {
        $memoryStream.Dispose()
        $bitmap.Dispose()
    }
}

function Save-IcoIcon {
    param(
        [string]$RelativePath,
        [int[]]$Sizes,
        [double]$Scale = $IconScale
    )

    $targetPath = Join-Path $projectRoot $RelativePath
    $targetDirectory = Split-Path -Parent $targetPath
    if (-not (Test-Path $targetDirectory)) {
        New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
    }

    $entries = foreach ($size in $Sizes) {
        [byte[]]$pngBytes = Get-PngBytes -Size $size -Scale $Scale
        [PSCustomObject]@{
            Size = $size
            Bytes = $pngBytes
        }
    }

    $fileStream = [System.IO.File]::Open($targetPath, [System.IO.FileMode]::Create)
    $writer = New-Object System.IO.BinaryWriter($fileStream)

    try {
        $writer.Write([UInt16]0)
        $writer.Write([UInt16]1)
        $writer.Write([UInt16]$entries.Count)

        $offset = 6 + (16 * $entries.Count)
        foreach ($entry in $entries) {
            $dimensionByte = if ($entry.Size -ge 256) { [byte]0 } else { [byte]$entry.Size }
            $writer.Write($dimensionByte)
            $writer.Write($dimensionByte)
            $writer.Write([byte]0)
            $writer.Write([byte]0)
            $writer.Write([UInt16]1)
            $writer.Write([UInt16]32)
            $writer.Write([UInt32]$entry.Bytes.Length)
            $writer.Write([UInt32]$offset)
            $offset += $entry.Bytes.Length
        }

        foreach ($entry in $entries) {
            $writer.Write($entry.Bytes)
        }
    } finally {
        $writer.Dispose()
        $fileStream.Dispose()
    }
}

$androidIcons = @(
    @{ Path = "android/app/src/main/res/mipmap-mdpi/ic_launcher.png"; Size = 48 },
    @{ Path = "android/app/src/main/res/mipmap-hdpi/ic_launcher.png"; Size = 72 },
    @{ Path = "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png"; Size = 96 },
    @{ Path = "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png"; Size = 144 },
    @{ Path = "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"; Size = 192 },
    @{ Path = "android/app/src/main/res/mipmap-mdpi/ic_launcher_round.png"; Size = 48 },
    @{ Path = "android/app/src/main/res/mipmap-hdpi/ic_launcher_round.png"; Size = 72 },
    @{ Path = "android/app/src/main/res/mipmap-xhdpi/ic_launcher_round.png"; Size = 96 },
    @{ Path = "android/app/src/main/res/mipmap-xxhdpi/ic_launcher_round.png"; Size = 144 },
    @{ Path = "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.png"; Size = 192 }
)

$iosIcons = @(
    @{ Path = "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png"; Size = 20 },
    @{ Path = "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png"; Size = 40 },
    @{ Path = "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png"; Size = 60 },
    @{ Path = "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png"; Size = 29 },
    @{ Path = "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png"; Size = 58 },
    @{ Path = "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png"; Size = 87 },
    @{ Path = "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png"; Size = 40 },
    @{ Path = "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png"; Size = 80 },
    @{ Path = "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png"; Size = 120 },
    @{ Path = "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png"; Size = 120 },
    @{ Path = "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png"; Size = 180 },
    @{ Path = "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png"; Size = 76 },
    @{ Path = "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png"; Size = 152 },
    @{ Path = "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png"; Size = 167 },
    @{ Path = "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png"; Size = 1024 }
)

$macosIcons = @(
    @{ Path = "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png"; Size = 16 },
    @{ Path = "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png"; Size = 32 },
    @{ Path = "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png"; Size = 64 },
    @{ Path = "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png"; Size = 128 },
    @{ Path = "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png"; Size = 256 },
    @{ Path = "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png"; Size = 512 },
    @{ Path = "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png"; Size = 1024 }
)

$webIcons = @(
    @{ Path = "web/favicon.png"; Size = 64 },
    @{ Path = "web/icons/Icon-192.png"; Size = 192 },
    @{ Path = "web/icons/Icon-512.png"; Size = 512 },
    @{ Path = "web/icons/Icon-maskable-192.png"; Size = 192 },
    @{ Path = "web/icons/Icon-maskable-512.png"; Size = 512 }
)

foreach ($icon in @($androidIcons + $iosIcons + $macosIcons + $webIcons)) {
    Save-PngIcon -RelativePath $icon.Path -Size $icon.Size
}

Save-IcoIcon -RelativePath "windows/runner/resources/app_icon.ico" -Sizes @(16, 24, 32, 48, 64, 128, 256)

$sourceBitmap.Dispose()

Write-Host "Generated app icons from $resolvedSourcePath"
