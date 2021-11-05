RED='\033[0;31m'
GREEN='\033[0;32m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

set -x #echo on

cd /home/element/labs/rabbitmq/certificados;

rm -rf keystore.p12;
rm -rf cacerts;

echo "${GREEN} generating keystore${NC}"
openssl pkcs12 -export -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -export -in ./alternative.rabbit.com.pem -inkey ./alternative.rabbit.com-key.pem -name myalias -out ./keystore.p12;

echo "${GREEN} generating cacerts${NC}"
keytool -import -alias servercert -file ./alternative.rabbit.com.pem -keystore ./cacerts;
keytool -import -alias cacert -file ./rootCA.pem -keystore ./cacerts;

echo "${GREEN} granting permissions for files${NC}"
chmod 664 *.pem;
chmod 664 *.p12;
chmod 664 cacerts;

cd -
