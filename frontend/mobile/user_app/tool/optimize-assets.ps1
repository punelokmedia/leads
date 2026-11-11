param([int]$MaxDimension = 1600, [int]$Quality = 82)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$appRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$assetRoot = Join-Path $appRoot 'assets'
$folders = @(
  '(POP) False Ceiling Work', 'AC Service & Repair', 'Aluminium & Windows',
  'CCTV Installation', 'Civil Work', 'Construction Enquiry', 'Electrical Work',
  'Interior Design', 'Painting', 'Plumbing', 'Real State', 'Water Proofing'
)
$encoder = [Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
  Where-Object MimeType -eq 'image/jpeg'
$before = (Get-ChildItem -LiteralPath $assetRoot -Recurse -File | Measure-Object Length -Sum).Sum
foreach ($folder in $folders) {
  foreach ($file in Get-ChildItem -LiteralPath (Join-Path $assetRoot $folder) -File) {
    if ($file.Extension -notin @('.jpg', '.png')) { continue }
    $destination = [IO.Path]::ChangeExtension($file.FullName, '.jpg')
    $temporary = $destination + '.optimized'
    $image = [Drawing.Image]::FromFile($file.FullName)
    try {
      $scale = [Math]::Min(1, $MaxDimension / [Math]::Max($image.Width, $image.Height))
      $bitmap = [Drawing.Bitmap]::new([Math]::Max(1, [int]($image.Width * $scale)), [Math]::Max(1, [int]($image.Height * $scale)))
      try {
        $graphics = [Drawing.Graphics]::FromImage($bitmap)
        try {
          $graphics.Clear([Drawing.Color]::White)
          $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
          $graphics.DrawImage($image, 0, 0, $bitmap.Width, $bitmap.Height)
        } finally { $graphics.Dispose() }
        $parameters = [Drawing.Imaging.EncoderParameters]::new(1)
        try {
          $parameters.Param[0] = [Drawing.Imaging.EncoderParameter]::new([Drawing.Imaging.Encoder]::Quality, [long]$Quality)
          $bitmap.Save($temporary, $encoder, $parameters)
        } finally { $parameters.Dispose() }
      } finally { $bitmap.Dispose() }
    } finally { $image.Dispose() }
    if ($file.Extension -eq '.png' -or (Get-Item -LiteralPath $temporary).Length -lt $file.Length) {
      Move-Item -LiteralPath $temporary -Destination $destination -Force
      if ($file.FullName -ne $destination) { Remove-Item -LiteralPath $file.FullName }
    } else { Remove-Item -LiteralPath $temporary }
  }
}
$after = (Get-ChildItem -LiteralPath $assetRoot -Recurse -File | Measure-Object Length -Sum).Sum
Write-Output "Assets before compression: $before bytes; after: $after bytes"
