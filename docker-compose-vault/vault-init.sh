#!/usr/bin/env sh

set -ex

unseal () {
vault operator unseal $(grep 'Key 1:' /vault/file/keys | awk '{print $NF}')
vault operator unseal $(grep 'Key 2:' /vault/file/keys | awk '{print $NF}')
vault operator unseal $(grep 'Key 3:' /vault/file/keys | awk '{print $NF}')
}

init () {
vault operator init > /vault/file/keys
}

log_in () {
   export ROOT_TOKEN=$(grep 'Initial Root Token:' /vault/file/keys | awk '{print $NF}')
   vault login $ROOT_TOKEN
}

if [ -s /vault/file/keys ]; then
   unseal
else
   init
   unseal
   log_in
   create_token
fi

vault status > /vault/file/status