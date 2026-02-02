#!/bin/bash

set -e  # Detiene el script ante cualquier error.

# Colores para la salida
RED='\033[0;31m'  # Rojo
GREEN='\033[0;32m'  # Verde
YELLOW='\033[1;33m'  # Amarillo
BLUE='\033[0;34m'  # Azul
CYAN='\033[0;36m'  # Cian
NC='\033[0m'  # Sin color

mostrar_titulo() {
  echo -e "${CYAN}Gestor de firma digital (RSA 4096)${NC}"  # Muestra el título del script.
}

generar_claves() {
  read -e -p "Directorio de salida: " out_dir  # Solicita el directorio destino.
  read -e -p "Nombre base de las claves (sin extensión): " base_name  # Solicita el nombre base.

  if [ -z "$out_dir" ] || [ -z "$base_name" ]; then  # Valida que ambos valores existan.
    echo -e "${RED}Debe indicar directorio de salida y nombre base.${NC}"  # Informa del error.
    return 1  # Vuelve al menú con error.
  fi

  mkdir -p "$out_dir"  # Crea el directorio de salida si no existe.

  priv_key="$out_dir/${base_name}.key.pem"  # Define la ruta de la clave privada.
  pub_key="$out_dir/${base_name}.pub.pem"  # Define la ruta de la clave pública.

  openssl genrsa -out "$priv_key" 4096  # Genera la clave privada RSA de 4096 bits.
  chmod 600 "$priv_key"  # Restringe permisos de la clave privada.
  openssl rsa -in "$priv_key" -pubout -out "$pub_key"  # Deriva la clave pública.

  echo -e "${GREEN}Clave privada:${NC} $priv_key"  # Muestra la ruta de la clave privada.
  echo -e "${GREEN}Clave pública:${NC} $pub_key"  # Muestra la ruta de la clave pública.
}

firmar_archivo() {
  read -e -p "Ruta del archivo a firmar: " file_path  # Solicita el archivo a firmar.
  read -e -p "Ruta de la clave privada (.key.pem): " key_path  # Solicita la clave privada.
  read -e -p "Ruta de salida de la firma (.sig): " sig_path  # Solicita la salida de la firma.

  if [ -z "$file_path" ] || [ -z "$key_path" ] || [ -z "$sig_path" ]; then  # Valida entradas.
    echo -e "${RED}Debe indicar archivo, clave privada y salida de firma.${NC}"
    return 1
  fi

  openssl dgst -sha256 -sign "$key_path" -out "$sig_path" "$file_path"  # Firma el archivo.
  echo -e "${GREEN}Firma creada:${NC} $sig_path"  # Muestra la ruta de la firma.
}

generar_publica_desde_privada() {
  read -e -p "Ruta de la clave privada (.key.pem): " key_path  # Solicita la clave privada.
  read -e -p "Ruta de salida de la clave pública (.pub.pem): " pub_path  # Solicita la salida.

  if [ -z "$key_path" ] || [ -z "$pub_path" ]; then  # Valida entradas.
    echo -e "${RED}Debe indicar clave privada y ruta de salida.${NC}"  # Informa del error.
    return 1  # Vuelve al menú con error.
  fi

  openssl rsa -in "$key_path" -pubout -out "$pub_path"  # Deriva la clave pública.
  echo -e "${GREEN}Clave pública generada:${NC} $pub_path"  # Muestra la ruta de la clave pública.
}

verificar_firma() {
  read -e -p "Ruta del archivo firmado: " file_path  # Solicita el archivo original.
  read -e -p "Ruta de la firma (.sig): " sig_path  # Solicita la firma.
  read -e -p "Ruta de la clave pública (.pub.pem): " pub_path  # Solicita la clave pública.

  if [ -z "$file_path" ] || [ -z "$sig_path" ] || [ -z "$pub_path" ]; then  # Valida entradas.
    echo -e "${RED}Debe indicar archivo, firma y clave pública.${NC}"
    return 1
  fi

  if openssl dgst -sha256 -verify "$pub_path" -signature "$sig_path" "$file_path"; then
    echo -e "${GREEN}Firma válida.${NC}"  # Indica que la firma es correcta.
  else
    echo -e "${RED}Firma inválida.${NC}"  # Indica que la firma es incorrecta.
  fi
}

info_firma() {
  read -e -p "Ruta del archivo firmado: " file_path  # Solicita el archivo original.
  read -e -p "Ruta de la firma (.sig): " sig_path  # Solicita la firma.

  if [ -z "$file_path" ] || [ -z "$sig_path" ]; then  # Valida entradas.
    echo -e "${RED}Debe indicar archivo y firma.${NC}"  # Informa del error.
    return 1  # Vuelve al menú con error.
  fi

  sig_size=$(wc -c < "$sig_path")  # Obtiene el tamaño de la firma en bytes.
  echo -e "${BLUE}Algoritmo:${NC} SHA-256"  # Indica el algoritmo usado.
  echo -e "${BLUE}Hash del archivo:${NC}"  # Etiqueta del hash.
  openssl dgst -sha256 "$file_path"  # Muestra el hash SHA-256 del archivo.
  echo -e "${BLUE}Tamaño de la firma:${NC} ${sig_size} bytes"  # Muestra el tamaño.
  echo -e "${BLUE}Firma (base64):${NC}"  # Etiqueta de la firma en base64.
  openssl base64 -in "$sig_path"  # Muestra la firma en base64.
}

menu() {
  while true; do
    echo -e "${BLUE}\n--- MENÚ ---${NC}"
    echo -e "${YELLOW}1.${NC} Generar claves RSA 4096"
    echo -e "${YELLOW}2.${NC} Generar clave pública desde privada"
    echo -e "${YELLOW}3.${NC} Firmar archivo"
    echo -e "${YELLOW}4.${NC} Verificar firma"
    echo -e "${YELLOW}5.${NC} Ver información de la firma"
    echo -e "${YELLOW}0.${NC} Salir"
    read -p "Opción> " opcion

    case $opcion in
      1) generar_claves ;;
      2) generar_publica_desde_privada ;;
      3) firmar_archivo ;;
      4) verificar_firma ;;
      5) info_firma ;;
      0) exit 0 ;;
      *) echo -e "${RED}Opción no reconocida.${NC}" ;;
    esac
  done
}

mostrar_titulo
menu
