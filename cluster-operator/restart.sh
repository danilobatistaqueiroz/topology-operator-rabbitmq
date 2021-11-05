RED='\033[0;31m'
GREEN='\033[0;32m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

#set -x #echo on

cd /home/element/labs/rabbitmq/cluster-operator


# minikube delete; minikube start;
kind delete cluster;./kind-with-registry.sh;
sleep 30;
echo -e "${GREEN}##################### cluster building finished #####################${NC}"

echo -e "${GREEN}##################### pushing images to local registry #####################${NC}"
docker pull rabbitmqoperator/cluster-operator:latest
docker tag rabbitmqoperator/cluster-operator:latest localhost:5000/rabbitmqoperator/cluster-operator:latest
docker push localhost:5000/rabbitmqoperator/cluster-operator:latest
#minikube image load localhost:5000/rabbitmqoperator/cluster-operator:latest

docker pull quay.io/metallb/speaker:main
docker tag quay.io/metallb/speaker:main localhost:5000/quay.io/metallb/speaker:main
docker push localhost:5000/quay.io/metallb/speaker:main
#minikube image load localhost:5000/quay.io/metallb/speaker:main

docker pull quay.io/metallb/controller:main
docker tag quay.io/metallb/controller:main localhost:5000/quay.io/metallb/controller:main
docker push localhost:5000/quay.io/metallb/controller:main
#minikube image load localhost:5000/quay.io/metallb/controller:main

docker pull rabbitmq:latest
docker tag rabbitmq:latest localhost:5000/rabbitmq:latest
docker push localhost:5000/rabbitmq:latest
#minikube image load localhost:5000/rabbitmq:latest

docker pull rabbitmq:3.8.21-management
docker tag rabbitmq:3.8.21-management localhost:5000/rabbitmq:3.8.21-management
docker push localhost:5000/rabbitmq:3.8.21-management
#minikube image load localhost:5000/rabbitmq:3.8.21-management

docker pull rabbitmqoperator/messaging-topology-operator:latest
docker tag rabbitmqoperator/messaging-topology-operator:latest localhost:5000/rabbitmqoperator/messaging-topology-operator:latest
docker push localhost:5000/rabbitmqoperator/messaging-topology-operator:latest
#minikube image load localhost:5000/rabbitmqoperator/messaging-topology-operator:latest

echo -e "${GREEN}##################### installing cluster operator #####################${NC}"
kubectl apply -f cluster-operator.yml;
echo -e "${GREEN}##################### metallb step start #####################${NC}"
kubectl apply -f metallb/namespace.yaml;
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)";
kubectl apply -f metallb/metallb.yaml;
kubectl apply -f metallb/metallb-configmap.yaml;
echo -e "${GREEN}##################### metallb step end #####################${NC}"
kubectl create namespace rabbit-ns;
kubectl config set-context --current --namespace=rabbit-ns;
kubectl apply -f ./tls-ca-secret.yaml;
echo -e "${GREEN}##################### starting rabbitmq deployment #####################${NC}"
kubectl apply -f ./rabbitmq-deploy-tls.yaml;
echo -e "${GREEN}##################### rabbitmq deployment finished #####################${NC}"


#kubectl exec -it triple-rabbit-server-0 -- rabbitmqctl add_user "danilo" "danilo";
#kubectl exec -it triple-rabbit-server-0 -- rabbitmqctl set_permissions -p "/" "danilo" ".*" ".*" ".*";

