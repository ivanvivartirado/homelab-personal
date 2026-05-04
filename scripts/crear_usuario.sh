#!/bin/bash

# Comprobar privilegios de root
if [ "$EUID" -ne 0 ]; then 
  echo "Error: Este script debe ejecutarse con sudo."
  exit 1
fi

echo "--- Gestión de Usuarios: Nexus Core ---"

# 1. Nombre de usuario
read -p "Nombre de usuario: " NUEVO_USER
if id "$NUEVO_USER" &>/dev/null; then
    echo "Error: El usuario '$NUEVO_USER' ya existe."
    exit 1
fi

# 2. Grupo
read -p "Grupo secundario (deja en blanco para ninguno): " GRUPO

# 3. Contraseña
read -sp "Contraseña para $NUEVO_USER: " PASSWORD
echo -e "\n"

# --- Ejecución ---

# Crear usuario con home y bash
useradd -m -s /bin/bash "$NUEVO_USER"

# Asignar contraseña
echo "$NUEVO_USER:$PASSWORD" | chpasswd

# Si se especificó un grupo, añadirlo
if [ -n "$GRUPO" ]; then
    # Crear grupo si no existe
    if ! getent group "$GRUPO" >/dev/null; then
        groupadd "$GRUPO"
        echo "Grupo '$GRUPO' creado."
    fi
    usermod -aG "$GRUPO" "$NUEVO_USER"
    echo "Usuario añadido al grupo '$GRUPO'."
fi

echo "Proceso finalizado: Usuario $NUEVO_USER configurado."
