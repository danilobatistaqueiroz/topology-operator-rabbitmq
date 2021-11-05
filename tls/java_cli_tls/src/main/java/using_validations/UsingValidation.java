package using_validations;

import java.io.*;
import java.net.Socket;
import java.security.*;
import java.security.cert.X509Certificate;
import java.util.Map;

import javax.net.ssl.*;

import org.apache.http.conn.ssl.SSLConnectionSocketFactory;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.ssl.PrivateKeyDetails;
import org.apache.http.ssl.PrivateKeyStrategy;
import org.apache.http.ssl.SSLContexts;
import org.apache.http.ssl.TrustStrategy;

import com.rabbitmq.client.*;

public class UsingValidation {
	
   
	private static KeyStore readStore() {
	  try (InputStream keyStoreStream = new FileInputStream("/home/element/labs/rabbitmq/selfcerts/truststore.pfx")) {
	    KeyStore keyStore = KeyStore.getInstance("PKCS12"); // or "JKS"
	    keyStore.load(keyStoreStream, "rabbit".toCharArray());
	    return keyStore;
	  } catch (Exception e) {
	    throw new RuntimeException(e);
	  }
	}
	
    private static void setSSLFactories(InputStream keyStream, String keystoreType, char[] keyStorePassword, char[] keyPassword) throws Exception
    {
        KeyStore keyStore = KeyStore.getInstance(keystoreType);

        keyStore.load(keyStream, keyStorePassword);

        KeyManagerFactory keyFactory =
                KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());

        keyFactory.init(keyStore, keyPassword);

        KeyManager[] keyManagers = keyFactory.getKeyManagers();

        SSLContext sslContext = SSLContext.getInstance("SSL");
        sslContext.init(keyManagers, null, null);
        SSLContext.setDefault(sslContext);
    }
	
	private static SSLContext getSslContext() {
		final KeyStore truststore = readStore();

        SSLContext sslContext = null;
		try {
			sslContext = SSLContexts.custom()
			        .loadKeyMaterial(readStore(), "rabbit".toCharArray(), (aliases, socket) -> "client cert key") 
			        .build();
		} catch (Exception e) {
			e.printStackTrace();
		}
        
		return sslContext;
	}
	
	public static void main (String[] args) {
	    try {
	      KeyStore identityKeyStore = KeyStore.getInstance("PKCS12");
	      FileInputStream identityKeyStoreFile = new FileInputStream(new File("/home/element/labs/rabbitmq/selfcerts/caclientstore"));
	      identityKeyStore.load(identityKeyStoreFile, "rabbit".toCharArray());
	      KeyStore trustKeyStore = KeyStore.getInstance("PKCS12");
	      FileInputStream trustKeyStoreFile = new FileInputStream(new File("/home/element/labs/rabbitmq/selfcerts/catruststore"));
	      trustKeyStore.load(trustKeyStoreFile, "rabbit".toCharArray());
	      SSLContext sslContext = SSLContexts.custom()
	    		  .loadKeyMaterial(identityKeyStore, "rabbit".toCharArray(), new PrivateKeyStrategy() {
		        	  @Override
		              public String chooseAlias(Map<String, PrivateKeyDetails> aliases, Socket socket) {
		                  return "caclientkeycert";
		              }
	          }).loadTrustMaterial(trustKeyStore, null).build();

	      

	      ConnectionFactory factory = new ConnectionFactory();
	      //factory.setUri("xrabbit:5671");
	      factory.setHost("xrabbit");
	      factory.setPort(5671);
	      //factory.setUsername("danilo");
	      //factory.setPassword("danilo");*/
	      factory.setSaslConfig(DefaultSaslConfig.EXTERNAL);
	      factory.useSslProtocol(sslContext);

	      factory.enableHostnameVerification();

	      Connection conn = factory.newConnection();
	      Channel channel = conn.createChannel();

	      channel.queueDeclare("rabbitmq-java-test", false, true, true, null);
	      channel.basicPublish("", "rabbitmq-java-test", null, "Hello, World".getBytes());

	      GetResponse chResponse = channel.basicGet("rabbitmq-java-test", false);
	      if (chResponse == null) {
	          System.out.println("No message retrieved");
	      } else {
	          byte[] body = chResponse.getBody();
	          System.out.println("Received: " + new String(body));
	      }

	      channel.close();
	      conn.close();

	    } catch (Exception ex) {
	      ex.printStackTrace();
	    }

	  }

    public static void mainx(String[] args) throws Exception {
      char[] keyPassphrase = "rabbit".toCharArray();
      KeyStore ks = KeyStore.getInstance("PKCS12");
      ks.load(new FileInputStream("/home/element/labs/rabbitmq/selfcerts/caclientkeycert.p12"), keyPassphrase);

      KeyManagerFactory kmf = KeyManagerFactory.getInstance("SunX509");
      kmf.init(ks, keyPassphrase);

      char[] trustPassphrase = "rabbit".toCharArray();
      KeyStore tks = KeyStore.getInstance("PKCS12");
      tks.load(new FileInputStream("/home/element/labs/rabbitmq/selfcerts/trust_store"), trustPassphrase);

      TrustManagerFactory tmf = TrustManagerFactory.getInstance("SunX509");
      tmf.init(tks);

      SSLContext c = SSLContext.getInstance("TLSv1.3");
      //SSLContext c = getSslContext();
      TrustStrategy acceptingTrustStrategy = (X509Certificate[] chain, String authType) -> true;

//      c.loadTrustMaterial(null, acceptingTrustStrategy); //accept all
      c.init(kmf.getKeyManagers(), tmf.getTrustManagers(), null);
      
      

      ConnectionFactory factory = new ConnectionFactory();
      //factory.setUri("xrabbit:5671");
      factory.setHost("xrabbit");
      factory.setPort(5671);
      //factory.setUsername("danilo");
      //factory.setPassword("danilo");*/
      factory.setSaslConfig(DefaultSaslConfig.EXTERNAL);
      factory.useSslProtocol(c);

      factory.enableHostnameVerification();

      Connection conn = factory.newConnection();
      Channel channel = conn.createChannel();

      channel.queueDeclare("rabbitmq-java-test", false, true, true, null);
      channel.basicPublish("", "rabbitmq-java-test", null, "Hello, World".getBytes());

      GetResponse chResponse = channel.basicGet("rabbitmq-java-test", false);
      if (chResponse == null) {
          System.out.println("No message retrieved");
      } else {
          byte[] body = chResponse.getBody();
          System.out.println("Received: " + new String(body));
      }

      channel.close();
      conn.close();
  }
}