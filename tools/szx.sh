#!/bin/sh
# szx.sh — Wrapper para compilar y ejecutar archivos .szx
#
# Uso:
#   ./tools/szx.sh apps/counter.szx

set -e

INPUT="$1"
if [ -z "$INPUT" ]; then
    echo "Uso: ./tools/szx.sh <archivo.szx>"
    exit 1
fi

if [ ! -f "$INPUT" ]; then
    echo "❌ Archivo no encontrado: $INPUT"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SZ_EXE="$SCRIPT_DIR/../../../Serez-code/target/release/sz"
TRANSLATE="$SCRIPT_DIR/translate.sz"
OUTPUT="${INPUT%.szx}.sz"

# Paso 1: traducir
"$SZ_EXE" "$TRANSLATE" "$INPUT" "$OUTPUT"

# Paso 2: ejecutar
"$SZ_EXE" "$OUTPUT"
