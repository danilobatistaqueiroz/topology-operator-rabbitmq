RABBIT_PATH=/home/element/labs/rabbitmq

$RABBIT_PATH/cluster-operator/restart.sh


cd $RABBIT_PATH/selfcerts/testca
export CA_PATH=$RABBIT_PATH/selfcerts/testca/ca.crt
kubectl -n rabbitmq-system create secret generic rabbitmq-ca --from-file=ca.crt=$CA_PATH

cd $RABBIT_PATH/oper-topology


kubectl create namespace my-app

kubectl apply -f webhook-server-cert.yml

kubectl apply -f messaging-topology-operator.yaml

sleep 10;

kubectl apply -f teste-queue.yml

#sleep 20;

#kubectl exec -it triple-rabbit-server-0 -- rabbitmqctl add_user "elementPC" "elementPC";
#kubectl exec -it triple-rabbit-server-0 -- rabbitmqctl set_permissions -p "/" "elementPC" ".*" ".*" ".*";
#kubectl exec -it triple-rabbit-server-0 -- rabbitmqctl set_user_tags elementPC administrator