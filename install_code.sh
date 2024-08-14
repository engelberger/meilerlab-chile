#!/bin/bash

# Obtener el directorio actual
PATH_TO_DIRECTORY=$(pwd)

# Nombre del archivo .deb
DEB_FILE="code_1.92.0-1722473020_amd64.deb"

# Cambiar al directorio donde se encuentra el archivo .deb
cd "$PATH_TO_DIRECTORY" || { echo "No se pudo cambiar al directorio $PATH_TO_DIRECTORY"; exit 1; }

# Instalar el archivo .deb
echo "Instalando $DEB_FILE..."
sudo dpkg -i "$DEB_FILE"

# Verificar si hubo problemas con dependencias y resolverlos
echo "Corrigiendo dependencias si es necesario..."
sudo apt-get install -f

echo "Instalación completada."

