#!/bin/bash

set -e

# Verificamos las dependencias necesarias para el correcto funcionamiento del script
echo "Verificando dependencias curl y unzip..."
for cmd in curl unzip; do
    if ! command -v $cmd &> /dev/null; then
        echo "ERROR: El comando '$cmd' no está instalado. Por favor instálalo e intenta de nuevo."
        exit 1
    fi
done

# Candado de seguridad
if [ "$EUID" -eq 0 ]; then
    echo "ERROR: Por favor ejecuta el script SIN la palabra 'sudo'."
    exit 1
fi

echo "================================================================"
echo " ACTUALIZADOR ONLINE DE LIBFFMPEG (CHROMIUM) PARA OPERA "
echo "================================================================"

# 1. Creamos una carpeta temporal en el sistema
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

echo "Buscando la última versión online del códec..."

# 2. Consultamos la API de GitHub para extraer el link de descarga exacto de Linux x64
DOWNLOAD_URL=$(curl -s https://api.github.com/repos/nwjs-ffmpeg-prebuilt/nwjs-ffmpeg-prebuilt/releases/latest | grep "browser_download_url.*linux-x64.zip" | cut -d '"' -f 4)

if [ -z "$DOWNLOAD_URL" ]; then
    echo "Error: No se pudo obtener el link de descarga desde GitHub."
    exit 1
fi

echo "Descargando paquete desde: $DOWNLOAD_URL"
curl -L -o ffmpeg.zip "$DOWNLOAD_URL"

echo "Descomprimiendo el archivo zip..."
unzip -q ffmpeg.zip

if [ ! -f "libffmpeg.so" ]; then
    echo "Error: El archivo libffmpeg.so no apareció al descomprimir."
    exit 1
fi

# 3. Fase de respaldo

# Obtenemos la ruta desde donde se está ejecutando el script y generamos el timestamp
EXEC_DIR="$PWD"
TIMESTAMP=$(date +"%Y%m%d%H%M%S")

# Obtenemos la ruta de la librería en Opera
OPERA_LIB_DIR="/usr/lib/x86_64-linux-gnu/opera-stable"
BACKUP_FILE="$EXEC_DIR/libffmpeg-${TIMESTAMP}.so"

if [ -f "$OPERA_LIB_DIR/libffmpeg.so" ]; then
    echo "Respaldando la libffmpeg original en: $BACKUP_FILE"
    cp "$OPERA_LIB_DIR/libffmpeg.so" "$BACKUP_FILE"
else
    echo "No se encontró el archivo libffmpeg.so original en la ruta $OPERA_LIB_DIR. Omitiendo respaldo..."
fi

# 4. Fase de inyección (AQUÍ TE PEDIRÁ CONTRASEÑA)
echo "Inyectando la nueva versión en Opera (Requiere permisos de sudo)..."
sudo cp libffmpeg.so "$OPERA_LIB_DIR/libffmpeg.so"
sudo chmod 644 "$OPERA_LIB_DIR/libffmpeg.so"

# 5. Limpiamos la basura generada (borra la carpeta temporal)
cd "$HOME"
rm -rf "$TEMP_DIR"

echo "¡Todo finalizado exitosamente! Reinicia Opera."
exit 0