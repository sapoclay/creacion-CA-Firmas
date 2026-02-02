#!/bin/bash

#PKI_PATH="/home/kali/Desktop/PKI"
#CONFIG="$PKI_PATH/openssl.cnf"

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

# Expedición de certificado a partir de un CSR
expedir_certificado() {
  read -e -p "Ruta del fichero CSR: " csr
  openssl ca -config $PKI_PATH/openssl.cnf -in "$csr" -out certificado.pem
  echo -e "${GREEN}Certificado creado correctamente con el archivo${NC}"
  echo ""
}

# Listado de certificados expedidos
listar_certificados() {
  echo ""
  echo -e "---${YELLOW}Listado de certificados:${NC}---"
  cat $PKI_PATH/index.txt
  echo ""
}

# Revocación de un certificados
revocar_certificado() {
  select serial in $(awk '$1=="V" {print $3}' $PKI_PATH/index.txt) ; do
    openssl ca -revoke $PKI_PATH/newcerts/$serial.pem -config $PKI_PATH/openssl.cnf
  done
}

# Comprobamos si la variable de entorno PKI_PATH está definida
if [ -z "$PKI_PATH" ] ; then
  echo -e "---${RED}Debe definirse PKI_PATH${NC}---"
  exit -1
fi

# Si no existe el directorio referido por $PKI_PATH, procedemos a crear la infraestructura
if [ ! -d "$PKI_PATH" ] ; then
  crear_infraestructura
fi

# Bucle sin fin para mostrar el menú de opciones
while true ; do
  echo -e "---${CYAN}MENÚ SIN GLUTEN${NC}---"
  cat << __FIN_MENU__
1. Expedir certificado
2. Listar certificados
3. Revocar certificado
0. Salir
__FIN_MENU__

  read -p "Opción> " opcion

  case $opcion in
    1) expedir_certificado ;;
    2) listar_certificados ;;
    3) revocar_certificado ;;
    0) exit ;;
    *) echo -e "${RED}Opción no reconocida.${NC}" ;;
  esac
done