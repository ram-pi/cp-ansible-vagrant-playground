#!/bin/sh
set -e

# Set home directory
cd $(dirname $0)

# Creating TLS CA, Certificates and keystore / truststore
rm -rf generated
mkdir -p generated

# Generate CA certificates
echo "Generate Self-Signed Root CA"
openssl req -new -nodes -x509 -days 3650 -newkey rsa:2048 -keyout generated/ca.key -out generated/ca.crt -config ca.cnf
cat generated/ca.crt generated/ca.key >generated/ca.pem

# Generate kafka client certificates
openssl req -new -newkey rsa:2048 -keyout generated/client.key -out generated/client.csr -config client.cnf -nodes
openssl x509 -req -days 3650 -in generated/client.csr -CA generated/ca.crt -CAkey generated/ca.key -CAcreateserial -out generated/client.crt -extfile client.cnf -extensions v3_req
# export client certificate to PKCS12 format
openssl pkcs12 -export -in generated/client.crt -inkey generated/client.key -chain -CAfile generated/ca.pem -name "myclient" -out generated/client.p12 -password pass:test1234

# Generate kafka server certificates
openssl req -new -newkey rsa:2048 -keyout generated/server.key -out generated/server.csr -config server.cnf -nodes
openssl x509 -req -days 3650 -in generated/server.csr -CA generated/ca.crt -CAkey generated/ca.key -CAcreateserial -out generated/server.crt -extfile server.cnf -extensions v3_req
# export client certificate to PKCS12 format
openssl pkcs12 -export -in generated/server.crt -inkey generated/server.key -chain -CAfile generated/ca.pem -name "kafka" -out generated/server.p12 -password pass:test1234

# Create pem encoded key pair to be used for signing and verifying JWT tokens
openssl genrsa -out generated/tokenKeypair.pem 2048
openssl rsa -in generated/tokenKeypair.pem -outform PEM -pubout -out generated/public.pem