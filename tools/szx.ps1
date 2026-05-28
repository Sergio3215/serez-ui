# szx.ps1 — Wrapper para compilar y ejecutar archivos .szx
#
# Uso desde E:\01 Proyectos\Propio\:
#   & "serez-ui\tools\szx.ps1" serez-ui\apps\counter.szx
#
# O desde serez-ui/:
#   & ".\tools\szx.ps1" apps\counter.szx

param([string]$InputFile)

if (-not $InputFile) {
    Write-Host "Uso: & 'serez-ui\tools\szx.ps1' <archivo.szx>"
    exit 1
}

$PARENT_DIR  = "$PSScriptRoot\..\.."   # E:\01 Proyectos\Propio
$SZ_EXE      = "$PARENT_DIR\Serez-code\target\release\sz.exe"
$TRANSLATE   = "$PSScriptRoot\translate.sz"

$ABS_INPUT   = (Resolve-Path $InputFile).Path
$ABS_OUTPUT  = $ABS_INPUT -replace '\.szx$', '.sz'

# Paso 1: traducir
& $SZ_EXE $TRANSLATE $ABS_INPUT $ABS_OUTPUT
if ($LASTEXITCODE -ne 0) { Write-Host "❌ Error en la traducción"; exit 1 }

# Paso 2: ejecutar desde el directorio padre (para que import "serez-ui" resuelva)
Push-Location $PARENT_DIR
$REL_OUTPUT = Resolve-Path -Relative $ABS_OUTPUT
& $SZ_EXE $REL_OUTPUT
Pop-Location
