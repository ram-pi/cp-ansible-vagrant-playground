# CP-Ansible playground with Vagrant

Playground for testing many [CP-Ansible](https://github.com/confluentinc/cp-ansible) configurations.

## Start Vagrant VM

```
vagrant up --no-tty
```

Vagrant VM will start this [docker-compose](https://github.com/ram-pi/docker-ldap/).  
OpenLDAP will be reachable at 192.168.33.10:389, phpldapadmin is accessible through your browser [here](http://192.168.33.10:8080) (`CN=admin,dc=confluent,dc=io / admin`). 

## Install Ansible collection

```
ansible-galaxy collection install confluent.platform --upgrade
```

## Managing secrets with ansible-vault (Create secret for ldap psw)

```
ansible-vault encrypt vars.yaml --output=vars.encrypted.yaml --vault-password-file=password.txt
```

## Create Server/Client certificates

```
./certs/up.sh
```

## Install CP through ansible

```
sudo ansible-playbook -i hosts.yaml confluent.platform.all -e @vars.encrypted.yaml --vault-password-file=password.txt
```

## mTLS Client

### Assign roles

```
vagrant ssh
export CONFLUENT_PLATFORM_MDS_URL=https://localhost:8090 
export CONFLUENT_USERNAME=superUser 
export CONFLUENT_PASSWORD=superUser
export CONFLUENT_PLATFORM_CA_CERT_PATH=/var/ssl/private/ca.crt
confluent cluster describe
confluent iam rbac role-binding create --principal User:myclient --role ResourceOwner --resource Topic:* --kafka-cluster kafka-cluster
confluent iam rbac role-binding create --principal User:myclient --role DeveloperRead --resource Group:* --kafka-cluster kafka-cluster
```

### Connect with Kafka CLI

```
export BOOTSTRAP_SERVER=192.168.33.10:9095
kafka-topics --bootstrap-server $BOOTSTRAP_SERVER --command-config client.mtls.properties --list
kafka-topics --bootstrap-server $BOOTSTRAP_SERVER --command-config client.mtls.properties --create --topic myclient-test
echo "test" | kafka-console-producer --bootstrap-server $BOOTSTRAP_SERVER --topic myclient-test --producer.config client.mtls.properties
kafka-console-consumer --bootstrap-server $BOOTSTRAP_SERVER --consumer.config client.mtls.properties --max-messages 1 --topic myclient-test --from-beginning
```

## LDAP Client

User `alice` is already part of the `admins` group.  
This user gets permissions from the inventory thanks to the following lines:

```
  kafka_broker_additional_system_admins:
    - Group:admins
```

### Connect with Kafka CLI

```
export BOOTSTRAP_SERVER=192.168.33.10:9097
kafka-topics --bootstrap-server $BOOTSTRAP_SERVER --command-config client.ldap.properties --list
kafka-topics --bootstrap-server $BOOTSTRAP_SERVER --command-config client.ldap.properties --create --topic alice-test
echo "test" | kafka-console-producer --bootstrap-server $BOOTSTRAP_SERVER --topic alice-test --producer.config client.ldap.properties
kafka-console-consumer --bootstrap-server $BOOTSTRAP_SERVER --consumer.config client.ldap.properties --max-messages 1 --topic alice-test --from-beginning
```

## OAUTH Client

### Connect with Kafka CLI

```
export BOOTSTRAP_SERVER=192.168.33.10:9092
kafka-topics --bootstrap-server $BOOTSTRAP_SERVER --command-config client.oauth.properties --list
kafka-topics --bootstrap-server $BOOTSTRAP_SERVER --command-config client.oauth.properties --create --topic oauth-test
echo "test" | kafka-console-producer --bootstrap-server $BOOTSTRAP_SERVER --topic oauth-test --producer.config client.oauth.properties
kafka-console-consumer --bootstrap-server $BOOTSTRAP_SERVER --consumer.config client.oauth.properties --max-messages 1 --topic oauth-test --from-beginning
```

## Destroy Env

```
vagrant destroy --no-tty
```