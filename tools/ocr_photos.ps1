# OCR every photo with the Windows built-in OCR engine (Windows PowerShell 5.1). Output: one line per photo in ocr.tsv
param([string]$Root = 'G:\HELLO BRO\Pictures', [string]$Out = "$PSScriptRoot\ocr.tsv")
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$null = [Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime]
$null = [Windows.Media.Ocr.OcrEngine, Windows.Foundation, ContentType = WindowsRuntime]
$null = [Windows.Graphics.Imaging.BitmapDecoder, Windows.Foundation, ContentType = WindowsRuntime]
$asTask = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
function Await($op, [Type]$t) { $task = $asTask.MakeGenericMethod($t).Invoke($null, @($op)); $task.Wait(-1) | Out-Null; $task.Result }
$engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages()
$done = @{}
if (Test-Path $Out) { Get-Content $Out -Encoding UTF8 | ForEach-Object { $done[($_ -split "`t")[0]] = 1 } }
$files = Get-ChildItem -Path $Root -Recurse -Include *.jpg, *.png | Sort-Object Name
$sw = New-Object System.IO.StreamWriter($Out, $true, [System.Text.Encoding]::UTF8)
$i = 0
foreach ($f in $files) {
  $i++
  $key = $f.Directory.Name + '/' + $f.Name
  if ($done[$key]) { continue }
  try {
    $file = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($f.FullName)) ([Windows.Storage.StorageFile])
    $stream = Await ($file.OpenAsync([Windows.Storage.FileAccessMode]::Read)) ([Windows.Storage.Streams.IRandomAccessStream])
    $dec = Await ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($stream)) ([Windows.Graphics.Imaging.BitmapDecoder])
    $bmp = Await ($dec.GetSoftwareBitmapAsync()) ([Windows.Graphics.Imaging.SoftwareBitmap])
    $res = Await ($engine.RecognizeAsync($bmp)) ([Windows.Media.Ocr.OcrResult])
    $text = ($res.Lines | ForEach-Object { $_.Text }) -join ' | '
    $stream.Dispose()
  } catch { $text = 'ERR ' + $_.Exception.Message }
  $sw.WriteLine($key + "`t" + ($text -replace "[`t`r`n]", ' '))
  if ($i % 100 -eq 0) { $sw.Flush(); Write-Host "$i / $($files.Count)" }
}
$sw.Close()
Write-Host "done $i"
