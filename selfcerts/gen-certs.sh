RED='\033[0;31m'
GREEN='\033[0;32m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

#set -x #echo on

cd /home/element/labs/rabbitmq/selfcerts

rm -rf testca;
rm -rf server;
rm -rf client;


mkdir testca;
mkdir server;
mkdir client;
cp openssl.txt testca/openssl.cnf;
cp openssl.txt server/openssl.cnf;
cp openssl.txt client/openssl.cnf;

echo -e "${GREEN}generating ca${NC}"

cd testca;
mkdir certs private;
chmod 700 private;
echo 01 > serial;
touch index.txt;
openssl req -x509 -config openssl.cnf -newkey rsa:2048 -days 365 -out ca.crt -outform PEM -subj /CN=MyTestCA/ -nodes;
openssl x509 -in ca.crt -out ca_certificate.cer -outform DER;

echo -e "${GREEN}generating operator${NC}"

cd ..;
cd server;
openssl genrsa -out private_key.pem 2048;
openssl req -new -key private_key.pem -config openssl.cnf -out req.pem -outform PEM -subj /CN=triple-rabbit-server-0/O=server/ -nodes;
cd ../testca;
openssl ca -config openssl.cnf -in ../server/req.pem -out ../server/oper_certificate.pem -notext -batch -extensions server_ca_extensions;
cd ../server;
openssl pkcs12 -export -out oper_certificate.p12 -in oper_certificate.pem -inkey private_key.pem -passout pass:rabbit;

echo -e "${GREEN}generating server${NC}"

cd ..;
cd server;
openssl genrsa -out private_key.pem 2048;
openssl req -new -key private_key.pem -config openssl.cnf -out req.pem -outform PEM -subj /CN=webhook-service.rabbitmq-system.svc/O=server/ -nodes;
cd ../testca;
openssl ca -config openssl.cnf -in ../server/req.pem -out ../server/server_certificate.pem -notext -batch -extensions server_ca_extensions;
cd ../server;
openssl pkcs12 -export -out server_certificate.p12 -in server_certificate.pem -inkey private_key.pem -passout pass:rabbit;

echo -e "${GREEN}generating client${NC}"

cd ..;
cd client;
openssl genrsa -out private_key.pem 2048;
openssl req -new -key private_key.pem -out req.pem -outform PEM -subj /CN=$(hostname)/O=client/ -nodes;
cd ../testca;
openssl ca -config openssl.cnf -in ../client/req.pem -out ../client/client_certificate.pem -notext -batch -extensions client_ca_extensions;
cd ../client;
openssl pkcs12 -export -out client_certificate.p12 -in client_certificate.pem -inkey private_key.pem -passout pass:rabbit;
cat private_key.pem client_certificate.pem>private_key_client_certificate.pem;

cd ..;
