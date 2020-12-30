#!/bin/bash
#Run the network through this shell-script.

#Having a sructure as configtx.yaml in the root folder and cyrpto-config.yaml in the root folder as well.
#Hence exporting the $PWD 
#Seting path to all bin commands i.e, peer, cyrptogen, etc.

export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}
export VERBOSE=true

# Versions of fabric known not to work with the test network
BLACKLISTED_VERSIONS="^1\.0\. ^1\.1\. ^1\.2\. ^1\.3\. ^1\.4\."

#Function to clear all the errors
#Called while bringing down the network
function clearContainers() {
  CONTAINER_IDS=$(docker ps -a | awk '($2 ~ /dev-peer.*/) {print $1}')
  if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" == " " ]; then
    echo "---- No containers available for deletion ----"
  else
    docker rm -f $CONTAINER_IDS
  fi
}

# Delete any images that were generated as a part of this setup
# specifically the following images are often left behind:
# This function is called when you bring the network down
function removeUnwantedImages() {
  DOCKER_IMAGE_IDS=$(docker images | awk '($1 ~ /dev-peer.*/) {print $3}')
  if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" == " " ]; then
    echo "---- No images available for deletion ----"
  else
    docker rmi -f $DOCKER_IMAGE_IDS
  fi
}

#Function to check the required pre-requisites
function checkPreqs() {
	#Check if binary folder and configuration files have been cloned properly.
	peer version > /dev/null 2>&1
	if [[ $? -ne 0 || ! -d "../config" ]]; then
		echo "Missing binaries or configuration files in given directories... clone the repo again"
	fi
	
	#Checking the cloned image version through peer version
	LCL_VERSION=$(peer version | sed -ne 's/ Version: //p')
	
	#Checking the docker image version 
	DOCKER_IMAGE_VERSION=$(docker run --rm hyperledger/fabric-tools:$IMAGETAG peer version | sed -ne 's/ Version: //p' | head -1)
	
	echo "LOCAL VERSION : $LCL_VERSION"
	echo "DOCKER IMAGE VERSION :  $DOCKER_IMAGE_VERSION"
	
	if [ "$LCL_VERSION" != "$DOCKER_IMAGE_VERSION" ]; then
		echo "ERROR: Local version and docker image version don't match"
	fi
	#grep is a tool to search for the given text in a file
	for UNSUP_VER in $BLACKLISTED_VERSIONS; do
		echo "$LCL_VERSION" | grep -q $UNSUP_VER 
		if [ $? -eq 0 ]; then
			echo "ERROR! Local Fabric binary version of $LCL_VERSION not supported by this network"
			exit 1
		fi
		
		echo "$DOCKER_IMAGE_VERSION" | grep -q $UNSUP_VER
		if [ $? -eq 0 ]; then
			echo "ERROR! Fabric Docker Image version of $DOCKER_IMAGE_VERSION not supported by this network"
			exit 1
		fi 
		done
}

#Function to create Organizations in the network as well to bring up the certs for organizations and their peers
function createOrgs() {

	#Checking if the organizations were already created, deleting them if already created
	if [ -d "organiztaions/peerOrganizations" ]; then
		rm -Rf organizations/peerOrganizations && rm -Rf organizations/ordererOrganizations
	fi
	
	echo "STARTING TLS-CA servers!!"
	sleep 3
	DOCKER_FILES="-f ${DOCKER_COMPOSE_TLS_CA_FILE}"

	IMAGE_TAG=$IMAGETAG docker-compose ${DOCKER_FILES} up -d 2>&1

	docker ps -a
	if [ $? -ne 0 ]; then
		echo "ERROR!!!!! TLS_CA_SERVER!!!!!"
		exit 1
	fi
	
	echo "STARTED TLS_CA_SERVER"	
	
	sleep 5

	
	
	echo "CREATING CRPTO MATERIAL FOR ORDERERS/ORGANIZATIONS"
	
	. scripts/upOrderer.sh 
	#sleep 3
	echo "####TLS for ORDERER ORGANIZATION####"
	sleep 3
	tls_createOrdererOrg
	sleep 3
	
	echo "####TLS for PEER ORGANIZATION####"
	sleep 3
	tls_createPeerOrgs
	sleep 3

	echo "Starting the CA-SERVER"	
	sleep 5
	
	DOCKER_FILES="-f ${DOCKER_COMPOSE_ORG_CA_FILE}"
	
	IMAGE_TAG=$IMAGETAG docker-compose ${DOCKER_FILES} up -d 2>&1
	
	docker ps -a
	if [ $? -ne 0 ]; then
		echo "ERROR!!!!! ORG_CA_SERVER!!!!!"
		exit 1
	fi	

	echo "STARTED ORG_CA_SERVER"
	
	sleep 5
	
	#. scripts/upCaOrderer.sh
	
	echo "####ORG_CA for ORDERER ORGANIZATION####"
	sleep 3
	org_createOrdererOrg
	sleep 3

	echo "####ORG_CA for PEER ORGANIZATION####"
	sleep 3
	orgca_createPeerOrgs
	sleep 3
	# #Check if cryptogen exists in the system
	# which cryptogen
	# if [ "$?" -ne 0 ]; then
	# 	echo "CRYPTOGEN missing!!"
	# fi
	
	# set -x
	# cryptogen generate --config=./crypto-config.yaml --output="organizations"
	# res=$?
	 set +x
	 #if [ $res -ne 0 ]; then
	 #	echo "Failed to generate certs"
	 #	exit 1
	 #fi
	#exit 1
}

#Function create the system channel's consortium with an orderer and 2 orgs
#This function generates the gensesis block
function createConsortium() {
	#check if configtxgen exists omn the system
	which configtxgen
	if [ "$?" -ne 0 ]; then
		echo "CONFIGTXGEN missing!!"
		exit 1
	fi
	
	echo "Generating Orderer genesis block"
	sleep 3
	set -x
	configtxgen -profile SampleMultiNodeEtcdRaft -channelID barterx-sys-channel -outputBlock ./channel-artifacts/genesis.block
	sleep 3
	res=$?
	set +x
	if [ $res -ne 0 ]; then
		echo "Failed genesis block!!"
		exit 1
	fi
}

#Function to start the network i.e, bring up the network
function startNetwork() {
	#Start with checking pre-requisites
	checkPreqs
	
	#Check if certs generated already, if not generate them
	if [ ! -d "organizations/peerOrganizations" ]; then
		#Create the organisations specified in the config files.
		createOrgs 
		createConsortium
	fi
	
	echo "Adding DOCKER COMPOSE FILES"
	sleep 3
	
	#Adding files to be composed in docker for creating containers
	COMPOSE_FILES="-f ${COMPOSE_BASE_FILE}" # -f ${COMPOSE_RAFT_FILE}"
	
	#Checking if couchDB selected, if yes, then adding couch compose file
	if [ "${DATABASE}" == "couchdb" ]; then
		COMPOSE_FILES="${COMPOSE_FILES} -f ${COMPOSE_COUCH_FILE}"
	fi
	
	IMAGE_TAG=$IMAGETAG docker-compose ${COMPOSE_FILES} up -d 2>&1
	
	#Checking if containers were brought up
	docker ps -a
	
	if [ $? -ne 0 ]; then
		echo "FAILED to bring up containers!!"
	fi
	
	sleep 5
	
	echo "Creating TX for channel confs with channelID : $CHANNEL_NAME"
	#Creating channel configuration tx file from configtx.yaml
	configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME
	#Running cli to bring up a sample channel
	
	#docker exec cli scripts/main_script.sh $CHANNEL_NAME $CLI_DELAY $CC_SRC_LANG $CLI_TIMEOUT $VERBOSE $NO_CHAINCODE
	
	if [ $? -ne 0 ]; then
		echo "CLI ERROR!!"
		exit 1
	fi
}

#Function to bring down the network or restart it
function networkStop() {
	#Bringing down all the conatianers
	IMAGE_TAG=$IMAGETAG docker-compose -f $COMPOSE_BASE_FILE down --volumes --remove-orphans #-f $COMPOSE_COUCH_FILE -f $COMPOSE_RAFT_FILE
	IMAGE_TAG=$IMAGETAG docker-compose -f $DOCKER_COMPOSE_TLS_CA_FILE down --volumes --remove-orphans
	IMAGE_TAG=$IMAGETAG docker-compose -f $DOCKER_COMPOSE_ORG_CA_FILE down --volumes --remove-orphans
	if [ "$MODE" != "restart" ]; then
		#Bringing down the whole network
		#clear the hosted containers
		clearContainers
		#Remove unwanted images (optional)
		removeUnwantedImages
		
		. scripts/downOrder.sh
		
		#remove channel and script artifacts generated
		rm -rf channel-artifacts/* .block channel-artifacts/*.tx organizations/ordererOrganizations organizations/peerOrganizations chaincode
		
		rm -rf organizations/fabric-ca/org2/org2_ca/org2admin organizations/fabric-ca/org2/org2_tls/org2admin organizations/fabric-ca/org2/org2_ca/tls organizations/fabric-ca/org1/org1_ca/tls 
	fi	
				
}

#Default variable declarations
IMAGETAG="latest"

COMPOSE_BASE_FILE=docker-compose-cli.yaml
#
COMPOSE_COUCH_FILE=docker-compose-couch.yaml
#TLS-CA docker compose file
DOCKER_COMPOSE_TLS_CA_FILE=docker/docker-compose-tlsca.yaml
#Org-CA server docker compose file
DOCKER_COMPOSE_ORG_CA_FILE=docker/docker-compose-ca.yaml
# org3 docker compose file
#COMPOSE_FILE_ORG3=docker-compose-org3.yaml
# two additional etcd/raft orderers
#COMPOSE_RAFT_FILE=docker-compose-etcdraft2.yaml
#Base file for creating containers
#COMPOSE_BASE_FILE=docker-compose-net-up.yaml
#YAML file for bringing up RAFT containers
#COMPOSE_RAFT_FILE=docker-compose-etcdraft2.yaml
#Couch compose file
#COMPOSE_COUCH_FILE=docker-compose-couch.yaml
#Delay between commands
CLI_DELAY=3
#Max wait time for a resposne
CLI_TIMEOUT=10
#channel name (default name)
CHANNEL_NAME="demochannel"
#Default language for Chaincodes
CC_SRC_LANG=go
#Database to be used
DATABASE="leveldb"

#Retrieve the mode i.e, the function to be performed
if [[ $# -lt 1 ]]; then
	exit 0
else
	MODE=$1
	shift	
fi

#Getting the arguments passed
while getopts "h?c:t:d:s:l:i:anv" opt; do
	case "$opt" in
	h | \?)
		echo "Help would be made available soon. Or the typed command is invalid"
		exit 0
		;;
	c)
		CHANNEL_NAME=$OPTARG
		;;
	t)
		CLI_TIMEOUT=$OPTARG
		;;
	d)
		CLI_DELAY=$OPTARG
		;;
	s)
		DATABASE=$OPTARG
		;;
	l)
		CC_SRC_LANG=$OPTARG
		;;
	i)
		IMAGETAG=$(go env GOARCH)"-"$OPTARG
		;;
	a)
		FARIC_CERT_AUTH=true
		;;
	n)
		NO_CHAINCODE=true
		;;
	v)
		VERBOSE=true
		;;
	esac
done

	
#Calling functions according to the MODE
if [ "$MODE" = "up" ]; then
	startNetwork
elif [ "$MODE" = "check" ]; then
	checkPreqs
elif [ "$MODE" = "createOrgs" ]; then
	createOrgs
elif [ "$MODE" = "createConst" ]; then
	createConsortium
elif [ "$MODE" = "down" ]; then
	networkStop
elif [ "$MODE" = "restart" ]; then
	networkStop
	startNetwork
else
	echo "WRONG COMMAND...will publish help later"
	exit 1
fi
