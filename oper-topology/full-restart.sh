cd ../selfcerts

./gen-certs.sh

./rebuild-secrets.sh

cd ../oper-topology

./restart-topology.sh