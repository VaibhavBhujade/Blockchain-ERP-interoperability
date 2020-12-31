#!/bin/bash

DOCKER_COMPOSE_TLS_CA_FILE=docker/docker-compose-tlsca.yaml
DOCKER_COMPOSE_ORG_CA_FILE=docker/docker-compose-ca.yaml
DOCKER_COMPOSE_ORDERER_FILE=docker-compose-orderers.yaml

IMAGETAG="latest"
IMAGE_TAG=$IMAGETAG docker-compose -f $DOCKER_COMPOSE_ORDERER_FILE -f $DOCKER_COMPOSE_ORG_CA_FILE -f $DOCKER_COMPOSE_TLS_CA_FILE down --volumes --remove-orphans #-f $COMPOSE_COUCH_FILE -f $COMPOSE_RAFT_FILE
	#if [ "$MODE" != "restart" ]; then
		#Bringing down the whole network
		#clear the hosted containers
CONTAINER_IDS=$(docker ps -a | awk '($2 ~ /dev-peer.*/) {print $1}')
if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" == " " ]; then
	echo "---- No containers available for deletion ----"
else
    docker rm -f $CONTAINER_IDS
fi
#Remove unwanted images (optional)
#removeUnwantedImages
DOCKER_IMAGE_IDS=$(docker images | awk '($1 ~ /dev-peer.*/) {print $3}')
if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" == " " ]; then
    echo "---- No images available for deletion ----"
else
    docker rmi -f $DOCKER_IMAGE_IDS
fi

#remove channel and script artifacts generated
rm -rf channel-artifacts/* .block channel-artifacts/*.tx #organizations
 rm -rf organizations/fabric-ca/ordererOrg/ca-ordererOrg/msp organizations/fabric-ca/ordererOrg/ca-ordererOrg/ca-cert.pem organizations/fabric-ca/ordererOrg/ca-ordererOrg/IssuerRevocationPublicKey organizations/fabric-ca/ordererOrg/ca-ordererOrg/tls organizations/fabric-ca/ordererOrg/ca-ordererOrg/fabric-ca-server.db organizations/fabric-ca/ordererOrg/ca-ordererOrg/IssuerPublicKey

rm -rf organizations/ordererOrganizations

 rm -rf organizations/fabric-ca/ordererOrg/tls-ordererOrg/ca-cert.pem organizations/fabric-ca/ordererOrg/tls-ordererOrg/tls-cert.pem organizations/fabric-ca/ordererOrg/tls-ordererOrg/IssuerRevocationPublicKey organizations/fabric-ca/ordererOrg/tls-ordererOrg/IssuerPublicKey organizations/fabric-ca/ordererOrg/tls-ordererOrg/fabric-ca-server.db organizations/fabric-ca/ordererOrg/tls-ordererOrg/msp
for peer in 1 2; do
	 rm -rf organizations/fabric-ca/org${peer}/org${peer}_tls/IssuerPublicKey organizations/fabric-ca/org${peer}/org${peer}_tls/IssuerRevocationPublicKey organizations/fabric-ca/org${peer}/org${peer}_tls/ca-cert.pem organizations/fabric-ca/org${peer}/org${peer}_tls/tls-cert.pem organizations/fabric-ca/org${peer}/org${peer}_tls/msp organizations/fabric-ca/org${peer}/org${peer}_tls/fabric-ca-server.db organizations/fabric-ca/org${peer}/org${peer}_tls/admin organizations/fabric-ca/org${peer}/org${peer}_tls/org1admin organizations/fabric-ca/org${peer}/org${peer}_tls/user1 organizations/fabric-ca/org${peer}/org${peer}_tls/peer0-org${peer} organizations/fabric-ca/org${peer}/org${peer}_tls/ca-org${peer}-admin

done
# rm -rf organizations/org2/org2_ca/org2admin organizations/org2/org2_tls/org2admin organizations/org2/org2_ca/tls organizations/org2/org1_ca/tls

for peer in 1 2; do
	 rm -rf organizations/fabric-ca/org${peer}/org${peer}_ca/IssuerPublicKey organizations/fabric-ca/org${peer}/org${peer}_ca/IssuerRevocationPublicKey organizations/fabric-ca/org${peer}/org${peer}_ca/ca-cert.pem organizations/fabric-ca/org${peer}/org${peer}_ca/tls-cert.pem organizations/fabric-ca/org${peer}/org${peer}_ca/msp organizations/fabric-ca/org${peer}/org${peer}_ca/fabric-ca-server.db organizations/fabric-ca/org${peer}/org${peer}_ca/admin organizations/fabric-ca/org${peer}/org${peer}_ca/org1admin organizations/fabric-ca/org${peer}/org${peer}_ca/user1 organizations/fabric-ca/org${peer}/org${peer}_ca/peer0-org${peer} organizations/fabric-ca/org${peer}/org${peer}_ca/ca-org${peer}-admin

done

rm -rf organizations/fabric-ca/ordererOrg/fab-ordererOrg-client/orderer-ca organizations/fabric-ca/ordererOrg/fab-ordererOrg-client/tls-ca organizations/fabric-ca/ordererOrg/fab-ordererOrg-client/tls-root-cert

#fi
