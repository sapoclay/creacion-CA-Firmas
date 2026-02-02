# CREAR-CA-BASH

Este repositorio incluye scripts Bash para gestionar una PKI básica y operaciones de firma digital con RSA 4096.

## Scripts

### pki.sh
- Crea la infraestructura mínima de una PKI en la ruta indicada por la variable de entorno `PKI_PATH`.
- Genera el archivo de configuración `openssl.cnf` necesario para la CA.
- Crea la clave privada y el certificado raíz de la CA.
- Permite:
  - Expedir certificados a partir de un CSR.
  - Listar certificados emitidos.
  - Revocar certificados.

**Uso básico:**
1. Exporta la variable `PKI_PATH` con la ruta de trabajo.
2. Ejecuta el script y sigue el menú.

### generar_claves.sh
- Proporciona un menú para operaciones de firma digital con RSA 4096.
- Permite:
  - Generar un par de claves (privada y pública).
  - Derivar la clave pública a partir de una clave privada existente.
  - Crear solicitudes de firma de certificado (CSR).
  - Firmar archivos.
  - Verificar firmas.
  - Mostrar información de una firma (hash, tamaño y base64).

**Uso básico:**
1. Ejecuta el script y selecciona una opción del menú.
2. Indica las rutas de entrada y salida cuando se solicite.

## Requisitos
- OpenSSL instalado en el sistema.

## Notas
- La clave pública siempre se deriva de la clave privada.
- Las rutas de salida se solicitan al usuario en tiempo de ejecución.
- La clave privada debe permanecer en posesión del usuario y no debe compartirse.
