#!/usr/bin/python3
import base64
ca_cert = open("/home/element/labs/rabbitmq/selfcerts/testca/ca.crt", "r").read()
en_ca_cert = base64.b64encode(ca_cert.encode(('ascii')))

with open("/home/element/labs/rabbitmq/oper-topology/messaging-topology-operator.yaml", "r") as file:
    filedata = file.read()

start = 0
end = 0
start = filedata.find('caBundle:',end)
while start > 0:
    end = filedata.find('\n',start)
    filedata = filedata[0:start] + f"caBundle: {en_ca_cert.decode('ascii')}" + filedata[end:]
    start = filedata.find('caBundle:',end)

with open("/home/element/labs/rabbitmq/oper-topology/messaging-topology-operator.yaml", "w") as file:
    file.write(filedata)


print('messaging topology configured')