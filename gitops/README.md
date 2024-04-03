# GitOps Example (WIP)

## Launch k8s cluster with kind 

```
kind create cluster
```

## Install Confluent Operator 

```
helm repo add confluentinc https://packages.confluent.io/helm --insecure-skip-tls-verify
helm repo update

# installing with debug enabled
helm upgrade --install confluent-operator confluentinc/confluent-for-kubernetes --namespace confluent --set debug="true" --create-namespace

# wait for pod to be ready
kubectl config set-context --current --namespace confluent
kubectl get pods -o wide -A
```

## Create CFK required secrets

```
# ca-cert secret
kubectl create secret generic cp-tls \
     --from-file=ca.crt=./certs/generated/ca.crt

kubectl create secret generic cp-credential \
     --from-file=bearer.txt=./bearer.txt \
     --namespace confluent

kubectl create secret generic kafka-tls \
     --from-file=tls.crt=./certs/generated/server.crt \
     --from-file=ca.crt=./certs/generated/ca.crt \
     --from-file=tls.key=./certs/generated/server.key

kubectl create secret generic cp-mds-pem \
     --from-file=mdsPublicKey.pem=./certs/generated/public.pem \
     --namespace confluent
```

## Create Connect, REST Proxy and KafkaRestClass

```
kubectl apply -f ./k8s/kafka-rest-class.yaml
kubectl apply -f ./k8s/kafka-rest-proxy.yaml
kubectl apply -f ./k8s/connect.yaml
```

## Create a new topic with CFK

```
kubectl apply -f ./k8s/topic.yaml
```

## Teardown

```
kind delete cluster
```
