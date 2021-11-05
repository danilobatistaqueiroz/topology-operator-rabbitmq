rm client_keystore.pkcs12;
rm trust_store;

openssl pkcs12 -export -in client/private_key_client_certificate.pem -out client_keystore.pkcs12 -name client -noiter -nomaciter;

keytool -import -keystore trust_store -file testca/ca.crt -alias theCARoot;
keytool -import -keystore trust_store -file server/server_certificate.pem -alias server;

