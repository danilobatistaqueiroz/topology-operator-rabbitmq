reset;
ls manual;
echo '####################### removing files ############################'
rm -rf manual/*;
ls manual;

echo '################### generating private key ########################'
# (genrsa) generate an RSA private key
openssl genrsa -out manual/ca-key.pem 2048;
echo '\n\n\n\n'

echo '############# generating a CA certificate request #################'
# (req) (-new) This option generates a new certificate request.
echo 'BR\nSP\nSP\n\nIT\nalternative.rabbit.com\ndanilobatistaqueiroz@gmail.com\n' | openssl req -new -x509 -nodes -days 1000 -key manual/ca-key.pem -out manual/ca-cert.pem;
echo '\n\n\n\n'

echo '############# generating a server certificate request #############'
# The (req) command primarily creates and processes certificate requests in PKCS#10 format.
# It can additionally create self signed certificates for use as root CAs for example.
# (-newkey) This option creates a new certificate request and a new private key.
echo 'BR\nSP\nSP\n\nIT\nalternative.rabbit.com\ndanilobatistaqueiroz@gmail.com\nrabbit\ndanilo.com' | openssl req -newkey rsa:2048 -days 1000 -nodes -keyout manual/server-key.pem -out manual/server-req.pem;
echo '\n\n\n\n'

echo '################### generating a server certificate ###############'
# (x509) sign certificate requests
# (-req) By default a certificate is expected on input. With this option a certificate request is expected.
# (-CA) Specifies the CA certificate to be used for signing. When this option is present x509 behaves like
# a "mini CA". The input file (-in) is signed by this CA using this option: that is its issuer name is set
# to the subject name of the CA and it is digitally signed using the CAs private key.
# (-CAkey) Sets the CA private key to sign a certificate with.
openssl x509 -req -in manual/server-req.pem -days 1000 -CA manual/ca-cert.pem -CAkey manual/ca-key.pem -set_serial 01 -out manual/server-cert.pem;
echo '\n\n\n\n'

echo '############# generating a client certificate request #############'
echo 'BR\nSP\nSP\n\nIT\nlocalhost\ndanilobatistaqueiroz@gmail.com\nrabbit\ndanilo.com' | openssl req -newkey rsa:2048 -days 1000 -nodes -keyout manual/client-key.pem -out manual/client-req.pem;
echo '\n\n\n\n'

echo '################# generating a client certificate #################'
openssl x509 -req -in manual/client-req.pem -days 1000 -CA manual/ca-cert.pem -CAkey manual/ca-key.pem -set_serial 01 -out manual/client-cert.pem;

# usar senha rabbit