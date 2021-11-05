é possível usar um statefulset, com uma imagem docker.  
é possível usar um helm chart com imagem da bitnami.  
é possível usar um operator diretamente.  
https://docs.bitnami.com/kubernetes/infrastructure/rabbitmq/administration/enable-tls/

criar certificados pode depender dos requisitos que a plataforma exige:  
https://stackoverflow.com/questions/10175812/how-to-generate-a-self-signed-ssl-certificate-using-openssl

é necessário se tornar uma CA próprio, ou seja, precisa gerar um Certificado ROOT, e assim,  
você mesmo ser seu Certification Authority:  
https://stackoverflow.com/questions/21297139/how-do-you-sign-a-certificate-signing-request-with-your-certification-authority/21340898#21340898  

com esses comandos, você cria seu certificado Root, e os certificados confiados:  `./gen-cert.sh`


É possível também usar configurações openssl.conf conforme o tutorial do Rabbitm:  
https://www.rabbitmq.com/ssl.html#manual-certificate-generation


#### Script para reiniciar todo o cluster
`
cd ~/labs/rabbitmq/cluster-operator;
kind delete cluster;./kind-with-registry.sh;
sleep 10;
kubectl apply -f https://github.com/rabbitmq/cluster-operator/releases/latest/download/cluster-operator.yml;
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/namespace.yaml;
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)";
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/metallb.yaml;
kubectl apply -f metallb-configmap.yaml;
kubectl create namespace rabbit-ns;
kubectl apply -f ~/labs/rabbitmq/cluster-operator/tls-ca-secret.yaml;
kubectl config set-context --current --namespace=rabbit-ns;
kubectl apply -f ~/labs/rabbitmq/cluster-operator/rabbitmq-deploy-tls.yaml;
sleep 30;
kubectl exec -it triple-rabbit-server-0 -- rabbitmqctl add_user "danilo" "danilo";
kubectl exec -it triple-rabbit-server-0 -- rabbitmqctl set_permissions -p "/" "danilo" ".*" ".*" ".*";
rm -rf ~/labs/rabbitmq/cluster-operator/tls/rabbitstore;
rm -rf ~/labs/rabbitmq/cluster-operator/tls/keystore.p12;

openssl pkcs12 -export -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -export -in ~/labs/rabbitmq/cluster-operator/tls/tls-gen/basic/result/client_certificate.pem -inkey ~/labs/rabbitmq/cluster-operator/tls/tls-gen/basic/result/client_key.pem -name myalias -out ~/labs/rabbitmq/cluster-operator/tls/keystore.p12;

keytool -import -alias server1 -file ~/labs/rabbitmq/cluster-operator/tls/tls-gen/basic/result/client_certificate.pem -keystore ~/labs/rabbitmq/cluster-operator/tls/rabbitstore;

`


#### criar o cluster kind kubernetes
cd ~/labs/rabbitmq/cluster-operator/

**delete o cluster**  
kind delete cluster  
**crie o cluster contendo um registry, portas para ingress, e 3 nós**  
./kind-with-registry.sh  

#### criar o operator e o cluster rabbitmq
kubectl apply -f "https://github.com/rabbitmq/cluster-operator/releases/latest/download/cluster-operator.yml"  
--ou--  
kubectl rabbitmq install-cluster-operator  



#### instalar metallb para aceitar LoadBalancer no kubernetes kind
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/namespace.yaml  
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"  
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/metallb.yaml  
docker network inspect -f '{{.IPAM.Config}}' kind  
cat metallb-configmap.yaml  
kubectl apply -f metallb-configmap.yaml  


#### criar o namespace
kubectl create namespace rabbit-ns  


#### essa é uma versão apenas para TLS sem usar criptografia peer-to-peer mTLS
` # usar senha rabbit `
openssl.cnf
`
        [ subject_alt_name ]
        subjectAltName = DNS:172.18.255.200, DNS:alternative.rabbit.com, DNS:www.rabbit.danilo.com, DNS: localhost
        [req]
        distinguished_name = req_distinguished_name
        req_extensions = v3_req
        prompt = no
        [req_distinguished_name]
        C = BR
        ST = SP
        L = SP
        O = MyCompany
        OU = MyDivision
        CN = www.rabbit.danilo.com
        [v3_req]
        keyUsage = keyEncipherment, dataEncipherment
        extendedKeyUsage = serverAuth
        subjectAltName = @alt_names
        [alt_names]
        DNS.1 = www.rabbit.danilo.com
        DNS.2 = alternative.rabbit.com
`
rm tls/cert.crt; rm tls/private.key  

openssl req -newkey rsa:4096 \
            -x509 \
            -sha256 \
            -days 3650 \
            -nodes \
            -config tls/openssl.cnf -extensions subject_alt_name \
            -subj '/C=gb/ST=edinburgh/L=edinburgh/O=mygroup/OU=servicing/CN=rabbit.danilo.com/emailAddress=danilobatistaqueiroz@gmail.com' \
            -out tls/cert.crt \
            -keyout tls/private.key  
cd ~/labs/rabbitmq/cluster-operator 
kubectl delete secret tls-secret  
kubectl create secret tls tls-secret --cert=./tls/cert.crt --key=./tls/private.key -n rabbit-ns  

#### essa é a versão peer-to-peer mTLS
**gerar os certificados**  
git clone https://github.com/michaelklishin/tls-gen tls-gen  
**remover os certificados se existirem**  
rm -rf ~/labs/rabbitmq/cluster-operator/tls/tls-gen/basic/result  
cd ~/labs/rabbitmq/cluster-operator/tls/tls-gen/basic  
# private key password
make PASSWORD=rabbit  
make verify  
make info  
ls -l ./result  
**configurar o secret com os certificados**  
cd ~/labs/rabbitmq/cluster-operator/tls/tls-gen/basic/result  
**encode base64 dos arquivos, pode ser feito online, ou com comando linux**  
$ base64 ca.crt | tr -d '\n' > ca_certificate.base64
$ base64 server_certificate.pem | tr -d '\n' > server_certificate.base64
$ base64 server_key.pem | tr -d '\n' > server_key.base64
--para fazer decode--  
$ base64 -d ca_certificate.base64  
--ou--  
https://www.base64encode.org/  
**editar o yaml para aplicar no kubectl**  
kubectl edit secret tls-secret  
`
apiVersion: v1
data:
  tls.crt: 
  tls.key: 
  ca.crt: 
kind: Secret
metadata:
  name: tls-ca-secret
  namespace: rabbit-ns
type: kubernetes.io/tls
`
pluma tls-ca-secret.yaml  
        ca.crt=./ca_certificate.base64  
        tls.crt=./server_certificate.base64  
        tls.key=./server_key.base64  

kubectl apply -f ~/labs/rabbitmq/cluster-operator/tls/tls-gen/basic/result/tls-ca-secret.yaml  

**secret criado manualmente**  
cd ~/labs/rabbitmq/cluster-operator/tls/manual  
kubectl create secret tls tls-manual-secret --cert=server-cert.pem --key=server-key.pem -n rabbit-ns  

kubectl get secrets  

#### namespace para o cluster rabbitmq
kubectl config set-context --current --namespace=rabbit-ns  

#### criar o cluster rabbitmq
**deletar um cluster existente**  
kubectl delete RabbitmqCluster triple-rabbit  
kubectl delete pod/triple-rabbit-server-0  
kubectl delete pod/triple-rabbit-server-1  
kubectl delete pod/triple-rabbit-server-2  
kubectl delete svc/triple-rabbit  
kubectl delete svc/triple-rabbit-nodes  
kubectl delete svc/rabbit-svc  
kubectl delete secret triple-rabbit-default-user  
kubectl delete secret triple-rabbit-erlang-cookie  
kubectl delete secret triple-rabbit-server-token-9vv58  
**criar o cluster**  
kubectl apply -f ~/labs/rabbitmq/cluster-operator/rabbitmq-deploy-tls.yaml  
kubectl apply -f ~/labs/rabbitmq/cluster-operator/load-balancer.yaml  
**para que nodeport funcione no kind, é necessário mapear a porta ao criar o cluster**  
kubectl apply -f ~/labs/rabbitmq/cluster-operator/node-port.yaml  
**verificar o cluster**  
kubectl get svc  
kubectl get pod  
kubectl get all  
NAME                   TYPE         CLUSTER-IP    EXTERNAL-IP     PORT  
service/triple-rabbit  LoadBalancer 10.96.186.6   172.18.255.200  5672:32439/TCP,15672:30034/TCP,15692:32573/TCP  

**as portas mapeadas são 15671 com TLS e 15672 sem TLS**  

### criar usuario
kubectl exec -it triple-rabbit-server-0 -- rabbitmqctl add_user "danilo" "danilo"  
kubectl exec -it triple-rabbit-server-0 -- rabbitmqctl set_permissions -p "/" "danilo" ".*" ".*" ".*"  


### verificar o cluster rabbitmq
 username="$(kubectl get secret triple-rabbit-default-user -o jsonpath='{.data.username}' | base64 --decode)"  
 password="$(kubectl get secret triple-rabbit-default-user -o jsonpath='{.data.password}' | base64 --decode)"  
 service="$(kubectl get service triple-rabbit -o jsonpath='{.spec.clusterIP}')"  
 kubectl run perf-test --image=pivotalrabbitmq/perf-test -- --uri amqp://$username:$password@$service  
 --ou--  
 kubectl rabbitmq perf-test triple-rabbit  

 echo $password  
 echo $username  
 kubectl logs --follow perf-test  
 kubectl delete pod perf-test  
 kubectl delete svc perf-test  


curl http://172.18.255.200:15672/  

pode-se acessar um pod diretamente:  
kubectl port-forward "pod/triple-rabbit-server-0" 15672  

curl http://localhost:15672/  






kubectl logs triple-rabbit-server-0  

kubectl rabbitmq tail triple-rabbit  

username="$(kubectl get secret triple-rabbit-default-user -o jsonpath='{.data.username}' | base64 --decode)"  
password="$(kubectl get secret triple-rabbit-default-user -o jsonpath='{.data.password}' | base64 --decode)"  
service="$(kubectl get service triple-rabbit -o jsonpath='{.spec.clusterIP}')"  
kubectl rabbitmq manage triple-rabbit  

kubectl exec -it triple-rabbit-server-0 -- bash  

rabbitmq@triple-rabbit-server-0:/$ rabbitmq-diagnostics listeners  
Asking node rabbit@triple-rabbit-server-0.triple-rabbit-nodes.rabbit-ns to report its protocol listeners ...  
Interface: [::], port: 15672, protocol: http, purpose: HTTP API  
Interface: [::], port: 15671, protocol: https, purpose: HTTP API over TLS (HTTPS)  
Interface: [::], port: 15692, protocol: http/prometheus, purpose: Prometheus exporter API over HTTP  
Interface: [::], port: 15691, protocol: https/prometheus, purpose: Prometheus exporter API over TLS (HTTPS)  
Interface: [::], port: 25672, protocol: clustering, purpose: inter-node and CLI tool communication  
Interface: [::], port: 5672, protocol: amqp, purpose: AMQP 0-9-1 and AMQP 1.0  
Interface: [::], port: 5671, protocol: amqp/ssl, purpose: AMQP 0-9-1 and AMQP 1.0 over TLS  


rabbitmq-plugins list  

rabbitmqctl cluster_status  

rabbitmq-diagnostics status  




#### usando java client
**deleta o keystore existente**  
rm -rf /home/element/labs/rabbitmq/cluster-operator/tls/rabbitstore  

**cria o keystore**  

cd ../selfcerts  
./gen-certs.sh  
./gen-stores.sh  

username="$(kubectl get secret triple-rabbit-default-user -o jsonpath='{.data.username}' | base64 --decode)"  
password="$(kubectl get secret triple-rabbit-default-user -o jsonpath='{.data.password}' | base64 --decode)"  
echo $username  
echo $password  



#### TLS cliente certificate
consultar o nome de cliente a ser usado:  
`openssl x509 -in client/client_certificate.pem -nameopt RFC2253 -subject -noout`

criar o keystore:  
`keytool -importkeystore -srckeystore caclientkeycert.p12 -srcstoretype pkcs12 -srcalias caclientkeycert -srcstorepass rabbit -destkeystore caclientstore -deststorepass rabbit -destalias caclientkeycert -deststoretype pkcs12`  

`keytool -import -alias caclientkeycert -file server/server_certificate.pem -keystore catruststore -deststorepass rabbit -srcstoretype pkcs1`  

criar o usuário:  
`kubectl exec -it triple-rabbit-server-0 -- rabbitmqctl add_user "client" "client";`  
`kubectl exec -it triple-rabbit-server-0 -- rabbitmqctl set_permissions -p "/" "client" ".*" ".*" ".*";`
`kubectl exec -it triple-rabbit-server-0 -- rabbitmqctl add_user "elementPC" "elementPC";`
`kubectl exec -it triple-rabbit-server-0 -- rabbitmqctl set_permissions -p "/" "elementPC" ".*" ".*" ".*";`
