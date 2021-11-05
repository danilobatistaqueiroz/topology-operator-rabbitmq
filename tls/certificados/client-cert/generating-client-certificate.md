**keystore**  
client's keystore is a **PKCS#12** format file containing:  
    1. The client's **public certificate**
    2. The client's **private key**  
    
`openssl pkcs12 -export -in client.crt -inkey client-private.key -out client.p12 -name "Whatever"` 

é necessário ter a chave privada no keystore do cliente.  

**truststore**  
The client's truststore is a straight forward **JKS** format file containing the **root certificate** or intermediate CA certificates.   

`keytool -genkey -dname "cn=CLIENT" -alias truststorekey -keyalg RSA -keystore ./client-truststore.jks -keypass whatever -storepass whatever`  
`keytool -import -keystore ./client-truststore.jks -file myca.crt -alias myca`  



**TrustStore** is used to store certificates from **Certified Authorities (CA)** that verify the certificate presented by the server in an SSL connection.  
While **Keystore** is used to store **private key** and **identity certificates** that a specific program should present to both parties (server or client) for verification.  


