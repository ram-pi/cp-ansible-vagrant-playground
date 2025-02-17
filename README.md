# CP-Ansible playground with Vagrant

Playground for testing many [CP-Ansible](https://github.com/confluentinc/cp-ansible) configurations.

## Prerequisites

- [Vagrant](https://developer.hashicorp.com/vagrant/docs/installation)
- [Virtualbox](https://www.virtualbox.org) or [VMware Hypervisor](https://www.vmware.com/products/desktop-hypervisor.html)
- [Docker Compose Vagrant Plugin](https://github.com/leighmcculloch/vagrant-docker-compose)

## Start Vagrant VM

```
vagrant up --no-tty
```

Vagrant VM will start this [docker-compose](https://github.com/ram-pi/docker-ldap/).  
OpenLDAP will be reachable at 192.168.33.10:389, phpldapadmin is accessible through your browser [here](http://192.168.33.10:8080) (`CN=admin,dc=confluent,dc=io / admin`). 

## Start Vagrant VM (On Apple Silicon Mac)

You might need to install [VMware Desktop for Mac](https://www.vmware.com/products/desktop-hypervisor.html).


You can launch your vagrant box like this:

```
VAGRANT_VAGRANTFILE=./vmware/Vagrantfile vagrant up --no-tty
```


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

### Inventories

You can try out different types of inventory:
- hosts.simple.yaml
- hosts.yaml with zookeeper and multiple listeners
- hosts.kraft.yaml with kraft and multiple listeners 
- hosts.kraft.sso.yaml with kraft and OIDC/mTLS 

### With Virtualbox Vagrant Provider

```
sudo ansible-playbook -i hosts.yaml confluent.platform.all -e @vars.encrypted.yaml --vault-password-file=password.txt
```

### With VMware Vagrant Provider

```
./certs/up.sh
sudo ansible-playbook -i hosts.yaml confluent.platform.all -e @vars.encrypted.yaml --vault-password-file=password.txt -e "ansible_ssh_private_key_file={{ inventory_dir }}/.vagrant/machines/default/vmware_desktop/private_key
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

## OIDC/mTLS RBAC

You can set up an "OIDC/mTLS" environment by following these steps:
- download confluent binaries version 7.8.0 or later (i.e. wget curl -O https://packages.confluent.io/archive/7.8/confluent-7.8.0.tar.gz)
- `sudo ansible-playbook -i hosts.kraft.sso.yaml confluent.platform.all`

### Connect with Kafka CLI

```
vagrant ssh
sudo su -
cd /opt/confluent/confluent-7.8.0/bin/
./kafka-topics --bootstrap-server confluent:9094 --command-config /opt/confluent/etc/kafka/client.properties --list
```

### Control Center

Open [https://192.168.33.10:9021](https://192.168.33.10:9021) and click on "Log in via SSO".

Use `superUser/superUser` to login. 


## kafka-ui

To use `kafka-ui` run
```
vagrant ssh
docker run -d --rm -it -p 1080:8080 -e DYNAMIC_CONFIG_ENABLED=true provectuslabs/kafka-ui
```


## Destroy Env

```
vagrant destroy --force
```