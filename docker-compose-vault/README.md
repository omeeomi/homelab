# Vault Server - docker-compose
Vault server has a unique mechanism during initializing in production mode. Running Vault in docker container normally needs manual action to make it work properly after installation.

In this repo you will find an easy way to deploy Vault in production mode without manual action. 

To start Vault server, clone the repo and run the following in the "docker-compose-vault" folder - 

```
docker-compose up -d
```
To access the root token, run the following- 
```
sudo docker exec -it vault grep 'Initial Root Token:' /vault/file/keys | awk '{print $NF}'
```

Alternatively, you can run the following to view the containers build out and watch the output of the commands- 
```
docker-compose up 
```

After inital setup you can stop and start the vault container with docker-compose down/up your vault server will be unsealed automatically. As long as the volume that is created on the host system is not deleted, the contents of the vault server (including the root token) will persist. 

Unsealing is automatic if you need unseal keys you can find it in _/vault/file/keys_ file in vault container.

This is an updated repo modified from the following repo ahmetkaftan developed-  
https://github.com/ahmetkaftan/docker-vault