#!/bin/bash

echo "[---Begin install-vault-systemd.sh---]"

echo "Setup Vault user"
export GROUP=vault
export USER=vault
export COMMENT=Vault
export HOME=/srv/vault
curl https://raw.githubusercontent.com/hashicorp/guides-configuration/master/shared/scripts/setup-user.sh | bash

echo "Install Vault"
export VERSION=${vault_version}
export URL=${vault_url}

echo "Running"

VAULT_VERSION=${VERSION}
VAULT_ZIP=vault_${VAULT_VERSION}_linux_amd64.zip
VAULT_URL=${URL:-https://releases.hashicorp.com/vault/${VAULT_VERSION}/${VAULT_ZIP}}
VAULT_DIR=/usr/local/bin
VAULT_PATH=${VAULT_DIR}/vault
VAULT_CONFIG_DIR=/etc/vault.d
VAULT_DATA_DIR=/opt/vault/data
VAULT_TLS_DIR=/opt/vault/tls
VAULT_ENV_VARS=${VAULT_CONFIG_DIR}/vault.conf
VAULT_PROFILE_SCRIPT=/etc/profile.d/vault.sh

echo "Downloading Vault ${VAULT_VERSION}"
[ 200 -ne $(curl --write-out %{http_code} --silent --output /tmp/${VAULT_ZIP} ${VAULT_URL}) ]

echo "Installing Vault"
sudo unzip -o /tmp/${VAULT_ZIP} -d ${VAULT_DIR}
sudo chmod 0755 ${VAULT_PATH}
sudo chown ${USER}:${GROUP} ${VAULT_PATH}
echo "$(${VAULT_PATH} --version)"

echo "Configuring Vault ${VAULT_VERSION}"
sudo mkdir -pm 0755 ${VAULT_CONFIG_DIR} ${VAULT_DATA_DIR} ${VAULT_TLS_DIR}

echo "Start Vault"
sudo tee ${VAULT_ENV_VARS} > /dev/null <<ENVVARS
ENVVARS

echo "Update directory permissions"
sudo chown -R ${USER}:${GROUP} ${VAULT_CONFIG_DIR} ${VAULT_DATA_DIR} ${VAULT_TLS_DIR}
sudo chmod -R 0644 ${VAULT_CONFIG_DIR}/*

echo "Set Vault profile script"
sudo tee ${VAULT_PROFILE_SCRIPT} > /dev/null <<PROFILE
export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_TOKEN=root
PROFILE

echo "Granting mlock syscall to vault binary"
sudo setcap cap_ipc_lock=+ep ${VAULT_PATH}

echo "Complete"

echo "Install Vault Systemd"
curl https://raw.githubusercontent.com/hashicorp/guides-configuration/master/vault/scripts/install-vault-systemd.sh | bash

echo "Cleanup install files"
curl https://raw.githubusercontent.com/hashicorp/guides-configuration/master/shared/scripts/cleanup.sh | bash

echo "Set variables"
VAULT_CONFIG_FILE=/etc/vault.d/default.hcl
VAULT_CONFIG_OVERRIDE_FILE=/etc/vault.d/z-override.hcl

echo "Minimal configuration for Vault"
cat <<CONFIG | sudo tee $VAULT_CONFIG_FILE
cluster_name = "${name}"
CONFIG

echo "Update Vault configuration file permissions"
sudo chown vault:vault $VAULT_CONFIG_FILE

if [ ${vault_override} == true ] || [ ${vault_override} == 1 ]; then
  echo "Add custom Vault server override config"
  cat <<CONFIG | sudo tee $VAULT_CONFIG_OVERRIDE_FILE
${vault_config}
CONFIG

  echo "Update Vault configuration override file permissions"
  sudo chown vault:vault $VAULT_CONFIG_OVERRIDE_FILE

  echo "If Vault config is overridden, don't start Vault in -dev mode"
  echo '' | sudo tee /etc/vault.d/vault.conf
fi

echo "Restart Vault"
sudo systemctl restart vault

echo "[---install-vault-systemd.sh Complete---]"