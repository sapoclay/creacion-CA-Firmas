#!/bin/bash

PKI_PATH="$HOME/Desktop/PKI"
CONFIG="$PKI_PATH/openssl.cnf"

# Colores para la salida
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Sin color

# Crea toda la PKI en una carpeta determinada por la variable de entorno PKI_PATH
crear_infraestructura() {
  # PKI_PATH debe contener algo, si no retornamos error
  if [ -z "$PKI_PATH" ] ; then return -1; fi
  echo ""
  echo -e "---${CYAN}CREACIÓN DE INFRAESTRUCTURA${NC}---"
  echo ""

  # Creación de carpetas
  mkdir -p $PKI_PATH/{certs,crl,private,newcerts}
  chmod 700 $PKI_PATH/private
  touch $PKI_PATH/index.txt
  echo 1000 | tee $PKI_PATH/serial | tee $PKI_PATH/crlnumber

  # Creación de configuración base
  cat > $PKI_PATH/openssl.cnf  << __CONFIG_END__
[ca]
default_ca = CA_default
[CA_default]
# Carpeta de trabajo
dir = $PKI_PATH

# Rutas a diferentes recursos
database = \$dir/index.txt
serial = \$dir/serial
certificate = \$dir/certs/ca.cert.pem
private_key = \$dir/private/ca.key.pem
new_certs_dir = \$dir/newcerts

# Parámetros
default_md = sha256
default_bits = 4096
default_days = 365
policy = policy_minimalist
default_crl_days = 30

[policy_minimalist]
# Sólo pediremos nombre
commonName = supplied

[req]
# Solicitudes firmadas de certificados
distinguished_name = req_dn
attributes = req_attr

[req_dn]
# Solicitud de datos
commonName = Solicitante

[req_attr]
# Atributos de la solicitud (no era obligatorio hacer esto pero molaba)
challengePassword = Password de la solicitud
challengePassword_min = 6
challengePassword_max = 20
__CONFIG_END__

  # Creación de clave privada y certificado raíz
  openssl genrsa -out $PKI_PATH/private/ca.key.pem 4096
  openssl req -x509 -new -nodes \
    -key $PKI_PATH/private/ca.key.pem \
    -sha256 -days 3650 -out $PKI_PATH/certs/ca.cert.pem
}

# Muestra el comando que se ejecutara
mostrar_comando() {
  echo -e "${BLUE}Comando:${NC} $*"
}

# Comprueba si la infraestructura de CA existe
requiere_ca() {
  if [ ! -f "$PKI_PATH/certs/ca.cert.pem" ] || [ ! -f "$PKI_PATH/private/ca.key.pem" ] || [ ! -f "$PKI_PATH/openssl.cnf" ]; then
    echo -e "${RED}La CA no esta creada. Usa la opcion 1 para crearla.${NC}"
    return 1
  fi
  return 0
}

# Expedición de certificado a partir de un CSR
expedir_certificado() {
  read -e -p "Ruta del fichero CSR: " csr
  mostrar_comando "openssl ca -config $PKI_PATH/openssl.cnf -in \"$csr\" -out certificado.pem"
  openssl ca -config $PKI_PATH/openssl.cnf -in "$csr" -out certificado.pem
  echo -e "${GREEN}Certificado creado correctamente con el archivo${NC}"
  echo ""
}

# Listado de certificados expedidos
listar_certificados() {
  echo ""
  echo -e "---${YELLOW}Listado de certificados:${NC}---"
  mostrar_comando "cat $PKI_PATH/index.txt"
  cat $PKI_PATH/index.txt
  echo ""
}

# Revocación de un certificados
revocar_certificado() {
  select serial in $(awk '$1=="V" {print $3}' $PKI_PATH/index.txt) ; do
    mostrar_comando "openssl ca -revoke $PKI_PATH/newcerts/$serial.pem -config $PKI_PATH/openssl.cnf"
    openssl ca -revoke $PKI_PATH/newcerts/$serial.pem -config $PKI_PATH/openssl.cnf
  done
}

# Verifica la firma de un certificado con el certificado del emisor
verificar_firma_certificado() {
  read -e -p "Ruta del certificado (.pem): " cert_path
  read -e -p "Ruta de la firma (.sig): " sig_path
  read -e -p "Ruta del certificado del emisor (.pem): " issuer_cert

  if [ -z "$cert_path" ] || [ -z "$sig_path" ] || [ -z "$issuer_cert" ]; then
    echo -e "${RED}Debe indicar certificado, firma y certificado del emisor.${NC}"
    return 1
  fi

  tmp_pub=$(mktemp)
  trap 'rm -f "$tmp_pub"' RETURN

  mostrar_comando "openssl x509 -in \"$issuer_cert\" -pubkey -noout > \"$tmp_pub\""
  openssl x509 -in "$issuer_cert" -pubkey -noout > "$tmp_pub"

  mostrar_comando "openssl dgst -sha256 -verify \"$tmp_pub\" -signature \"$sig_path\" \"$cert_path\""
  if openssl dgst -sha256 -verify "$tmp_pub" -signature "$sig_path" "$cert_path"; then
    echo -e "${GREEN}Firma valida.${NC}"
  else
    echo -e "${RED}Firma invalida.${NC}"
  fi
}

# Verifica la firma de un certificado con una clave publica
verificar_firma_certificado_pub() {
  read -e -p "Ruta del certificado (.pem): " cert_path
  read -e -p "Ruta de la firma (.sig): " sig_path
  read -e -p "Ruta de la clave publica (.pub.pem): " pub_path

  if [ -z "$cert_path" ] || [ -z "$sig_path" ] || [ -z "$pub_path" ]; then
    echo -e "${RED}Debe indicar certificado, firma y clave publica.${NC}"
    return 1
  fi

  mostrar_comando "openssl dgst -sha256 -verify \"$pub_path\" -signature \"$sig_path\" \"$cert_path\""
  if openssl dgst -sha256 -verify "$pub_path" -signature "$sig_path" "$cert_path"; then
    echo -e "${GREEN}Firma valida.${NC}"
  else
    echo -e "${RED}Firma invalida.${NC}"
  fi
}

# Muestra toda la informacion de un certificado
ver_info_certificado() {
  read -e -p "Ruta del certificado (.pem): " cert_path

  if [ -z "$cert_path" ]; then
    echo -e "${RED}Debe indicar la ruta del certificado.${NC}"
    return 1
  fi

  mostrar_comando "openssl x509 -in \"$cert_path\" -noout -text"
  openssl x509 -in "$cert_path" -noout -text
}

# Comprobamos si la variable de entorno PKI_PATH está definida
if [ -z "$PKI_PATH" ] ; then
  echo -e "---${RED}Debe definirse PKI_PATH${NC}---"
  exit -1
fi

# Bucle sin fin para mostrar el menú de opciones
while true ; do
  if [ ! -f "$PKI_PATH/certs/ca.cert.pem" ]; then
    echo -e "${YELLOW}Aviso:${NC} La CA aun no esta creada. Usa la opcion 1 para crearla."
  fi
  echo -e "---${CYAN}MENÚ SIN GLUTEN${NC}---"
  cat << __FIN_MENU__
1. Crear infraestructura de CA
2. Expedir certificado
3. Listar certificados
4. Revocar certificado
5. Verificar firma de certificado (con emisor)
6. Ver informacion de certificado
7. Verificar firma de certificado (con clave publica)
0. Salir
__FIN_MENU__

  read -p "Opción> " opcion

  case $opcion in
    1) crear_infraestructura ;;
    2) requiere_ca && expedir_certificado ;;
    3) requiere_ca && listar_certificados ;;
    4) requiere_ca && revocar_certificado ;;
    5) verificar_firma_certificado ;;
    6) ver_info_certificado ;;
    7) verificar_firma_certificado_pub ;;
    0) exit ;;
    *) echo -e "${RED}Opción no reconocida.${NC}" ;;
  esac
done