#!/usr/bin/python3
import base64
ca_cert = open("/home/element/labs/rabbitmq/selfcerts/testca/ca.crt", "r").read()
en_ca_cert = base64.b64encode(ca_cert.encode(('ascii')))
server_cert = open("/home/element/labs/rabbitmq/selfcerts/server/server_certificate.pem", "r").read()
en_server_cert = base64.b64encode(server_cert.encode(('ascii')))
server_key = open("/home/element/labs/rabbitmq/selfcerts/server/private_key.pem", "r").read()
en_server_key = base64.b64encode(server_key.encode(('ascii')))

f = open("/home/element/labs/rabbitmq/cluster-operator/tls-ca-secret.yaml", "w")
f.write(f"""apiVersion: v1
data:
  tls.crt: {en_server_cert.decode('ascii')}
  tls.key: {en_server_key.decode('ascii')}
  ca.crt: {en_ca_cert.decode('ascii')}
kind: Secret
metadata:
  name: tls-ca-secret
  namespace: rabbit-ns
type: kubernetes.io/tls"""
)
f.close()

print('tls-ca-secret created')