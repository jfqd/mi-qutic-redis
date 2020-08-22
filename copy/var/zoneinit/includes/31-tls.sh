# This script will try to manage the ssl certificates for us. It will
# use the mdata variable if provided, if it does not exists we will
# try to get a certificate from the Let's Encrypt API.
# As fallback the self-signed certificate is used from 45-ssl-selfsigned.sh

# Default
TLS_HOME='/opt/local/etc/tls/'

# Create folder if it doesn't exists
mkdir -p "${TLS_HOME}"
chmod 0750 "${TLS_HOME}"

# Use user certificate if provided
if mdata-get redis_tls_pem 1>/dev/null 2>&1; then
  (
  umask 0077
  mdata-get redis_tls_pem > "${TLS_HOME}/redis.pem"
  # Split files for nginx usage
  openssl pkey -in "${TLS_HOME}/redis.pem" -out "${TLS_HOME}/redis.key"
  openssl crl2pkcs7 -nocrl -certfile "${TLS_HOME}/redis.pem" | \
    openssl pkcs7 -print_certs -out "${TLS_HOME}/redis.crt"
  )
  chmod 0640 "${TLS_HOME}"/redis.*
  chown -R redis:redis "${TLS_HOME}"
fi
