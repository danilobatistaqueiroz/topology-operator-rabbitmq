CERTS=/home/element/labs/rabbitmq/selfcerts
cd $CERTS
rm caclientkeycert.p12 ca_client_key_cert.pem caclientstore catruststore client_keystore.p12 truststore.pfx trust_store

cat testca/ca_certificate.pem client/client_certificate.pem client/private_key.pem > ca_client_key_cert.pem

openssl pkcs12 -export -in ca_client_key_cert.pem -out caclientkeycert.p12 -name caclientkeycert -noiter -nomaciter

keytool -importkeystore -srckeystore caclientkeycert.p12 -srcstoretype pkcs12 -srcalias caclientkeycert -srcstorepass rabbit -destkeystore caclientstore -deststorepass rabbit -destalias caclientkeycert -deststoretype pkcs12

keytool -import -alias caclientkeycert -file server/server_certificate.pem -keystore catruststore -deststorepass rabbit -srcstoretype pkcs12