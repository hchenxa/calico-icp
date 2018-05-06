#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail


DEBUG="${DEBUG:-false}"

if [ "${DEBUG}" == "true" ]; then
    set -x
fi

etcd_master_hosts="$1,$2"

mkdir -p "$CERT_DIR"

tmpdir=$(mktemp -d -t etcd_cacert.XXXXXX)
trap 'rm -rf "${tmpdir}"' EXIT
cd "${tmpdir}"

echo '{"CN":"SUBJECT","key":{"algo":"rsa","size":2048}}' > ca.json
sed -i "s/SUBJECT/$1/g" ca.json
cat ca.json | cfssl gencert -initca - | cfssljson -bare ca -

echo '{"signing":{"default":{"expiry":"876000h","usages":["signing","key encipherment","server auth","client auth"]}}}' > ca-config.json

echo '{"CN":"SUBJECT","hosts":[""],"key":{"algo":"rsa","size":2048}}' > cert.json
sed -i "s/SUBJECT/$1/g" cert.json
cat cert.json | cfssl gencert -config=ca-config.json -ca=ca.pem -ca-key=ca-key.pem -hostname="$etcd_master_hosts" - | cfssljson -bare server

cat cert.json | cfssl gencert -config=ca-config.json -ca=ca.pem -ca-key=ca-key.pem -hostname="" - | cfssljson -bare client

cp -p ca.pem "${CERT_DIR}/ca.pem"
cp -p ca-key.pem "${CERT_DIR}/ca-key.pem"
cp -p server.pem "${CERT_DIR}/server.pem"
cp -p server-key.pem "${CERT_DIR}/server-key.pem"
cp -p client.pem "${CERT_DIR}/client.pem"
cp -p client-key.pem "${CERT_DIR}/client-key.pem"
