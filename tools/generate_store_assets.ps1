$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$iconDir = Join-Path $projectRoot "assets\store\icons"
$listingDir = Join-Path $projectRoot "assets\store\listing"

New-Item -ItemType Directory -Force -Path $iconDir, $listingDir, (Join-Path $listingDir "screenshots") | Out-Null

function New-RoundedRectanglePath {
	param(
		[float]$X,
		[float]$Y,
		[float]$Width,
		[float]$Height,
		[float]$Radius
	)

	$diameter = $Radius * 2.0
	$path = New-Object System.Drawing.Drawing2D.GraphicsPath
	$path.AddArc($X, $Y, $diameter, $diameter, 180, 90)
	$path.AddArc($X + $Width - $diameter, $Y, $diameter, $diameter, 270, 90)
	$path.AddArc($X + $Width - $diameter, $Y + $Height - $diameter, $diameter, $diameter, 0, 90)
	$path.AddArc($X, $Y + $Height - $diameter, $diameter, $diameter, 90, 90)
	$path.CloseFigure()
	return $path
}

function New-BitmapContext {
	param(
		[int]$Width,
		[int]$Height
	)

	$bitmap = New-Object System.Drawing.Bitmap $Width, $Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
	$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
	$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
	$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
	$graphics.Clear([System.Drawing.Color]::Transparent)
	return @{
		Bitmap = $bitmap
		Graphics = $graphics
	}
}

function Save-Bitmap {
	param(
		[System.Drawing.Bitmap]$Bitmap,
		[string]$Path
	)

	$Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
	$Bitmap.Dispose()
}

function Fill-RoundedRectangle {
	param(
		[System.Drawing.Graphics]$Graphics,
		[System.Drawing.Brush]$Brush,
		[float]$X,
		[float]$Y,
		[float]$Width,
		[float]$Height,
		[float]$Radius
	)

	$path = New-RoundedRectanglePath -X $X -Y $Y -Width $Width -Height $Height -Radius $Radius
	$Graphics.FillPath($Brush, $path)
	$path.Dispose()
}

function Draw-Grid {
	param(
		[System.Drawing.Graphics]$Graphics,
		[int]$Width,
		[int]$Height,
		[System.Drawing.Color]$Color,
		[int]$Spacing
	)

	$pen = New-Object System.Drawing.Pen $Color, 1
	for ($x = 0; $x -le $Width; $x += $Spacing) {
		$Graphics.DrawLine($pen, $x, 0, $x, $Height)
	}

	for ($y = 0; $y -le $Height; $y += $Spacing) {
		$Graphics.DrawLine($pen, 0, $y, $Width, $y)
	}

	$pen.Dispose()
}

function Draw-Hexagon {
	param(
		[System.Drawing.Graphics]$Graphics,
		[float]$CenterX,
		[float]$CenterY,
		[float]$Radius,
		[System.Drawing.Brush]$Brush,
		[System.Drawing.Pen]$Pen = $null
	)

	$points = New-Object "System.Drawing.PointF[]" 6
	for ($index = 0; $index -lt 6; $index++) {
		$angle = ((-90 + ($index * 60)) * [Math]::PI) / 180.0
		$points[$index] = [System.Drawing.PointF]::new(
			$CenterX + ([Math]::Cos($angle) * $Radius),
			$CenterY + ([Math]::Sin($angle) * $Radius)
		)
	}

	$Graphics.FillPolygon($Brush, $points)
	if ($Pen) {
		$Graphics.DrawPolygon($Pen, $points)
	}
}

function Draw-Diamond {
	param(
		[System.Drawing.Graphics]$Graphics,
		[float]$CenterX,
		[float]$CenterY,
		[float]$Radius,
		[System.Drawing.Brush]$Brush
	)

	$points = New-Object "System.Drawing.PointF[]" 4
	$points[0] = [System.Drawing.PointF]::new($CenterX, $CenterY - $Radius)
	$points[1] = [System.Drawing.PointF]::new($CenterX + $Radius, $CenterY)
	$points[2] = [System.Drawing.PointF]::new($CenterX, $CenterY + $Radius)
	$points[3] = [System.Drawing.PointF]::new($CenterX - $Radius, $CenterY)
	$Graphics.FillPolygon($Brush, $points)
}

function Draw-CitaforgeEmblem {
	param(
		[System.Drawing.Graphics]$Graphics,
		[float]$CenterX,
		[float]$CenterY,
		[float]$Radius,
		[bool]$Monochrome = $false
	)

	$shadowBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(70, 9, 12, 18))
	$outerBrush = if ($Monochrome) {
		New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 232, 232, 232))
	} else {
		New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml("#35506a"))
	}
	$innerBrush = if ($Monochrome) {
		New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 248, 248, 248))
	} else {
		New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml("#e1a65f"))
	}
	$coreRingBrush = if ($Monochrome) {
		New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 214, 214, 214))
	} else {
		New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml("#1d2731"))
	}
	$coreBrush = if ($Monochrome) {
		New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
	} else {
		New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml("#70d3c0"))
	}
	$highlightBrush = if ($Monochrome) {
		New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
	} else {
		New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml("#f7e6be"))
	}
	$outlinePen = if ($Monochrome) {
		New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 224, 224, 224), ($Radius * 0.05))
	} else {
		New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(220, 247, 230, 190), ($Radius * 0.05))
	}
	$signalPen = if ($Monochrome) {
		New-Object System.Drawing.Pen ([System.Drawing.Color]::White, ($Radius * 0.08))
	} else {
		New-Object System.Drawing.Pen ([System.Drawing.ColorTranslator]::FromHtml("#70d3c0"), ($Radius * 0.08))
	}
	$signalPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
	$signalPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round

	Draw-Hexagon -Graphics $Graphics -CenterX ($CenterX + ($Radius * 0.04)) -CenterY ($CenterY + ($Radius * 0.06)) -Radius ($Radius * 1.02) -Brush $shadowBrush
	Draw-Hexagon -Graphics $Graphics -CenterX $CenterX -CenterY $CenterY -Radius $Radius -Brush $outerBrush
	Draw-Hexagon -Graphics $Graphics -CenterX $CenterX -CenterY $CenterY -Radius ($Radius * 0.76) -Brush $innerBrush -Pen $outlinePen

	$pylonSize = $Radius * 0.22
	$pylonRadius = $Radius * 0.07
	Fill-RoundedRectangle -Graphics $Graphics -Brush $outerBrush -X ($CenterX - ($pylonSize * 0.5)) -Y ($CenterY - ($Radius * 0.88)) -Width $pylonSize -Height ($pylonSize * 0.74) -Radius $pylonRadius
	Fill-RoundedRectangle -Graphics $Graphics -Brush $outerBrush -X ($CenterX - ($pylonSize * 0.5)) -Y ($CenterY + ($Radius * 0.34)) -Width $pylonSize -Height ($pylonSize * 0.74) -Radius $pylonRadius
	Fill-RoundedRectangle -Graphics $Graphics -Brush $outerBrush -X ($CenterX - ($Radius * 0.88)) -Y ($CenterY - ($pylonSize * 0.37)) -Width ($pylonSize * 0.74) -Height $pylonSize -Radius $pylonRadius
	Fill-RoundedRectangle -Graphics $Graphics -Brush $outerBrush -X ($CenterX + ($Radius * 0.34)) -Y ($CenterY - ($pylonSize * 0.37)) -Width ($pylonSize * 0.74) -Height $pylonSize -Radius $pylonRadius

	$Graphics.FillEllipse($coreRingBrush, $CenterX - ($Radius * 0.28), $CenterY - ($Radius * 0.28), $Radius * 0.56, $Radius * 0.56)
	$Graphics.FillEllipse($coreBrush, $CenterX - ($Radius * 0.19), $CenterY - ($Radius * 0.19), $Radius * 0.38, $Radius * 0.38)
	Draw-Diamond -Graphics $Graphics -CenterX $CenterX -CenterY $CenterY -Radius ($Radius * 0.12) -Brush $highlightBrush

	$braceBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(72, 14, 20, 28))
	Draw-Diamond -Graphics $Graphics -CenterX $CenterX -CenterY ($CenterY - ($Radius * 0.48)) -Radius ($Radius * 0.08) -Brush $braceBrush
	Draw-Diamond -Graphics $Graphics -CenterX $CenterX -CenterY ($CenterY + ($Radius * 0.48)) -Radius ($Radius * 0.08) -Brush $braceBrush
	Draw-Diamond -Graphics $Graphics -CenterX ($CenterX - ($Radius * 0.48)) -CenterY $CenterY -Radius ($Radius * 0.08) -Brush $braceBrush
	Draw-Diamond -Graphics $Graphics -CenterX ($CenterX + ($Radius * 0.48)) -CenterY $CenterY -Radius ($Radius * 0.08) -Brush $braceBrush

	$Graphics.DrawArc($signalPen, $CenterX + ($Radius * 0.18), $CenterY - ($Radius * 1.02), $Radius * 0.72, $Radius * 0.72, -30, 80)
	$Graphics.DrawArc($signalPen, $CenterX + ($Radius * 0.02), $CenterY - ($Radius * 1.18), $Radius * 1.04, $Radius * 1.04, -26, 72)

	$shadowBrush.Dispose()
	$outerBrush.Dispose()
	$innerBrush.Dispose()
	$coreRingBrush.Dispose()
	$coreBrush.Dispose()
	$highlightBrush.Dispose()
	$outlinePen.Dispose()
	$signalPen.Dispose()
	$braceBrush.Dispose()
}

function Draw-IconArt {
	param(
		[System.Drawing.Graphics]$Graphics,
		[int]$Size
	)

	$padding = [float]($Size * 0.08)
	$radius = [float]($Size * 0.17)
	$brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush ([System.Drawing.PointF]::new(0, 0)), ([System.Drawing.PointF]::new($Size, $Size)), ([System.Drawing.ColorTranslator]::FromHtml("#121820")), ([System.Drawing.ColorTranslator]::FromHtml("#253544"))
	Fill-RoundedRectangle -Graphics $Graphics -Brush $brush -X $padding -Y $padding -Width ($Size - ($padding * 2)) -Height ($Size - ($padding * 2)) -Radius $radius
	$brush.Dispose()

	Draw-Grid -Graphics $Graphics -Width $Size -Height $Size -Color ([System.Drawing.Color]::FromArgb(18, 255, 255, 255)) -Spacing ([Math]::Max([int]($Size / 10), 16))

	$accentBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(36, 211, 173, 88))
	$Graphics.FillEllipse($accentBrush, $Size * 0.1, $Size * 0.1, $Size * 0.8, $Size * 0.8)
	$accentBrush.Dispose()

	Draw-CitaforgeEmblem -Graphics $Graphics -CenterX ($Size * 0.5) -CenterY ($Size * 0.54) -Radius ($Size * 0.25)
}

function Write-MainIcon {
	param(
		[int]$Size,
		[string]$Path
	)

	$ctx = New-BitmapContext -Width $Size -Height $Size
	Draw-IconArt -Graphics $ctx.Graphics -Size $Size
	$ctx.Graphics.Dispose()
	Save-Bitmap -Bitmap $ctx.Bitmap -Path $Path
}

function Write-IOSAppIcon {
	param(
		[string]$Path
	)

	$size = 1024
	# App Store icons must be square, must not contain transparency, and must
	# not have pre-rounded corners. iOS applies the final mask on the device.
	$bitmap = New-Object System.Drawing.Bitmap $size, $size, ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
	$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
	$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
	$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
	$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

	$backgroundBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush ([System.Drawing.PointF]::new(0, 0)), ([System.Drawing.PointF]::new($size, $size)), ([System.Drawing.ColorTranslator]::FromHtml("#121820")), ([System.Drawing.ColorTranslator]::FromHtml("#325066"))
	$graphics.FillRectangle($backgroundBrush, 0, 0, $size, $size)
	$backgroundBrush.Dispose()

	Draw-Grid -Graphics $graphics -Width $size -Height $size -Color ([System.Drawing.Color]::FromArgb(22, 255, 255, 255)) -Spacing 96
	$accentBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(42, 127, 176, 105))
	$graphics.FillEllipse($accentBrush, $size * 0.1, $size * 0.1, $size * 0.8, $size * 0.8)
	$accentBrush.Dispose()
	Draw-CitaforgeEmblem -Graphics $graphics -CenterX ($size * 0.5) -CenterY ($size * 0.54) -Radius ($size * 0.27)

	$graphics.Dispose()
	$bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
	$bitmap.Dispose()
}

function Write-AdaptiveBackground {
	param(
		[int]$Size,
		[string]$Path
	)

	$ctx = New-BitmapContext -Width $Size -Height $Size
	$brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush ([System.Drawing.PointF]::new(0, 0)), ([System.Drawing.PointF]::new($Size, $Size)), ([System.Drawing.ColorTranslator]::FromHtml("#121820")), ([System.Drawing.ColorTranslator]::FromHtml("#325066"))
	$ctx.Graphics.FillRectangle($brush, 0, 0, $Size, $Size)
	$brush.Dispose()

	Draw-Grid -Graphics $ctx.Graphics -Width $Size -Height $Size -Color ([System.Drawing.Color]::FromArgb(24, 255, 255, 255)) -Spacing ([Math]::Max([int]($Size / 8), 32))

	$accentBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(36, 127, 176, 105))
	$ctx.Graphics.FillEllipse($accentBrush, $Size * 0.08, $Size * 0.08, $Size * 0.84, $Size * 0.84)
	$accentBrush.Dispose()

	$ctx.Graphics.Dispose()
	Save-Bitmap -Bitmap $ctx.Bitmap -Path $Path
}

function Write-AdaptiveForeground {
	param(
		[int]$Size,
		[string]$Path,
		[bool]$Monochrome = $false
	)

	$ctx = New-BitmapContext -Width $Size -Height $Size
	Draw-CitaforgeEmblem -Graphics $ctx.Graphics -CenterX ($Size * 0.5) -CenterY ($Size * 0.56) -Radius ($Size * 0.23) -Monochrome $Monochrome
	$ctx.Graphics.Dispose()
	Save-Bitmap -Bitmap $ctx.Bitmap -Path $Path
}

function Write-FeatureGraphic {
	param(
		[string]$Path
	)

	$width = 1024
	$height = 500
	$ctx = New-BitmapContext -Width $width -Height $height

	$backgroundBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush ([System.Drawing.PointF]::new(0, 0)), ([System.Drawing.PointF]::new($width, $height)), ([System.Drawing.ColorTranslator]::FromHtml("#121820")), ([System.Drawing.ColorTranslator]::FromHtml("#1f3040"))
	$ctx.Graphics.FillRectangle($backgroundBrush, 0, 0, $width, $height)
	$backgroundBrush.Dispose()

	Draw-Grid -Graphics $ctx.Graphics -Width $width -Height $height -Color ([System.Drawing.Color]::FromArgb(18, 255, 255, 255)) -Spacing 48

	$leftAccent = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(28, 127, 176, 105))
	$rightAccent = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(36, 211, 173, 88))
	$ctx.Graphics.FillEllipse($leftAccent, -70, 170, 340, 340)
	$ctx.Graphics.FillEllipse($rightAccent, 660, -30, 390, 390)
	$leftAccent.Dispose()
	$rightAccent.Dispose()

	Draw-CitaforgeEmblem -Graphics $ctx.Graphics -CenterX 812 -CenterY 250 -Radius 126

	$titleFont = New-Object System.Drawing.Font "Segoe UI Black", 46, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
	$subtitleFont = New-Object System.Drawing.Font "Segoe UI Semibold", 22, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
	$bodyFont = New-Object System.Drawing.Font "Segoe UI", 18, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
	$titleBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 246, 248, 250))
	$accentBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml("#d3ad58"))
	$bodyBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(230, 225, 232, 238))

	$ctx.Graphics.DrawString("AKSOY TANK", $titleFont, $titleBrush, 72, 118)
	$ctx.Graphics.DrawString("Mobil arcade savunma aksiyonu", $subtitleFont, $accentBrush, 74, 186)
	$bodyRect = [System.Drawing.RectangleF]::new(74, 240, 470, 120)
	$ctx.Graphics.DrawString("Cekirdegi koru, hatta baski kur ve 10 elde hazirlanan bolumu temizle.", $bodyFont, $bodyBrush, $bodyRect)

	$titleFont.Dispose()
	$subtitleFont.Dispose()
	$bodyFont.Dispose()
	$titleBrush.Dispose()
	$accentBrush.Dispose()
	$bodyBrush.Dispose()

	$ctx.Graphics.Dispose()
	Save-Bitmap -Bitmap $ctx.Bitmap -Path $Path
}

Write-MainIcon -Size 192 -Path (Join-Path $iconDir "android-main-192.png")
Write-MainIcon -Size 512 -Path (Join-Path $listingDir "google-play-icon-512.png")
Write-IOSAppIcon -Path (Join-Path $iconDir "ios-app-icon-1024.png")
Write-AdaptiveBackground -Size 432 -Path (Join-Path $iconDir "android-adaptive-background-432.png")
Write-AdaptiveForeground -Size 432 -Path (Join-Path $iconDir "android-adaptive-foreground-432.png")
Write-AdaptiveForeground -Size 432 -Path (Join-Path $iconDir "android-adaptive-monochrome-432.png") -Monochrome $true
Write-FeatureGraphic -Path (Join-Path $listingDir "google-play-feature-graphic-1024x500.png")

Write-Host "Store assetleri uretildi:"
Write-Host " - $iconDir"
Write-Host " - $listingDir"
