#!/bin/bash

IMAGETAG="latest"

#Setting path for TLS-CA server
#export FABRIC_CA_SERVER_HOME=${PWD}/organizations/fabric-ca/ordererOrg/tls-ordererOrg

#starting the TLS-CA
#set -x
#fabric-ca-server start
#set +x

#DOCKER_COMPOSE_TLS_CA_FILE=docker/docker-compose-tlsca.yaml
#DOCKER_COMPOSE_ORG_CA_FILE=docker/docker-compose-ca.yaml

#DOCKER_FILES="-f ${DOCKER_COMPOSE_TLS_CA_FILE}"

#IMAGE_TAG=$IMAGETAG docker-compose ${DOCKER_FILES} up -d 2>&1

#docker ps -a
#if [ $? -ne 0 ]; then
#	echo "ERROR!!!!! TLS_CA_SERVER!!!!!"
#	exit 1
#fi

#echo "STARTED TLS_CA_SERVER"	

#sleep 5

function tls_createOrdererOrg() {
	#making the client directory
	mkdir -p organizations/fabric-ca/ordererOrg/fab-ordererOrg-client

	#making the tls-root-cert directory to store ca.pem of TLS-CA
	mkdir -p organizations/fabric-ca/ordererOrg/fab-ordererOrg-client/tls-root-cert
	mkdir -p organizations/fabric-ca/ordererOrg/fab-ordererOrg-client/tls-ca
	mkdir -p organizations/fabric-ca/ordererOrg/ca-ordererOrg/tls
	#Copy ca-cert.pem to above created directory
	cp ${PWD}/organizations/fabric-ca/ordererOrg/tls-ordererOrg/ca-cert.pem ${PWD}/organizations/fabric-ca/ordererOrg/fab-ordererOrg-client/tls-root-cert/tls-ca-cert.pem

	#export path for ca client
	export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/fabric-ca/ordererOrg/fab-ordererOrg-client

	#Enroll TLS-CA admin using above tls-cert
	set -x
	fabric-ca-client enroll -d -u https://admin:adminpw@localhost:9054 --tls.certfiles tls-root-cert/tls-ca-cert.pem --csr.hosts *.example.com,localhost --mspdir tls-ca/tlsadmin/msp
	set +x
	#sleep 5

	#Generate a rcadmin for org-CA
	set -x
	fabric-ca-client register -d --id.name rc7admin --id.secret rcadminpw -u https://localhost:9054 --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir tls-ca/tlsadmin/msp
	set +x
	#sleep 5

	#Enroll the rcadmin
	set -x
	fabric-ca-client enroll -d -u https://rc7admin:rcadminpw@localhost:9054 --tls.certfiles tls-root-cert/tls-ca-cert.pem --csr.hosts *.example.com,localhost --mspdir tls-ca/rcadmin/msp
	set +x
	#sleep 5

	#Copy the signed cert from msp of rcadmin to tls folder of orderer-ca
	cp ${PWD}/organizations/fabric-ca/ordererOrg/fab-ordererOrg-client/tls-ca/rcadmin/msp/signcerts/* ${PWD}/organizations/fabric-ca/ordererOrg/ca-ordererOrg/tls/cert.pem

	#Copy the private key of rcadmin from msp/keystore to tls
	cp ${PWD}/organizations/fabric-ca/ordererOrg/fab-ordererOrg-client/tls-ca/rcadmin/msp/keystore/* ${PWD}/organizations/fabric-ca/ordererOrg/ca-ordererOrg/tls/key.pem

	
		
	#. upCaOrderer.sh
	
	
	sleep 5
}


function tls_createPeerOrgs() {
	  
	export FABRIC_CA_CLIENT_HOME=${PWD}

  	#enroll tls-ca-org1 admin  
  	fabric-ca-client enroll -d -u https://tls-org1-admin:tls-org1-adminpw@localhost:7052 --tls.certfiles organizations/fabric-ca/org1/org1_tls/ca-cert.pem --csr.hosts *.org1.example.com,localhost --mspdir organizations/fabric-ca/org1/org1_tls/admin/tlsca 

  	#enroll tls-ca-org2 admin  
  	fabric-ca-client enroll -d -u https://tls-org2-admin:tls-org2-adminpw@localhost:8052 --tls.certfiles organizations/fabric-ca/org2/org2_tls/ca-cert.pem --csr.hosts *.org2.example.com,localhost --mspdir organizations/fabric-ca/org2/org2_tls/admin/tlsca

  	#register admin of ca-org1 to tls ca of org1
  	fabric-ca-client register -d --id.name ca-org1-admin --id.secret ca-org1-adminpw -u https://localhost:7052 --tls.certfiles organizations/fabric-ca/org1/org1_tls/ca-cert.pem --mspdir organizations/fabric-ca/org1/org1_tls/admin/tlsca

  	#enroll admin of ca-org1 to tls ca of org1
  	fabric-ca-client enroll -d -u https://ca-org1-admin:ca-org1-adminpw@localhost:7052 --tls.certfiles organizations/fabric-ca/org1/org1_tls/ca-cert.pem --csr.hosts *.org1.example.com,localhost --mspdir organizations/fabric-ca/org1/org1_tls/ca-org1-admin/tls

  	#register admin of ca-org2 to tls ca of org2
  	fabric-ca-client register -d --id.name ca-org2-admin --id.secret ca-org2-adminpw -u https://localhost:8052 --tls.certfiles organizations/fabric-ca/org2/org2_tls/ca-cert.pem --mspdir organizations/fabric-ca/org2/org2_tls/admin/tlsca

  	#enroll admin of ca-org2 to tls ca of org2
  	fabric-ca-client enroll -d -u https://ca-org2-admin:ca-org2-adminpw@localhost:8052 --tls.certfiles organizations/fabric-ca/org2/org2_tls/ca-cert.pem --csr.hosts *.org2.example.com,localhost --mspdir organizations/fabric-ca/org2/org2_tls/ca-org2-admin/tls

	for peer in 1 2; do
		mkdir -p organizations/fabric-ca/org${peer}/org${peer}_ca/tls
		#Copy the signed cert from msp of rcadmin to tls folder of orderer-ca
		cp ${PWD}/organizations/fabric-ca/org${peer}/org${peer}_tls/ca-org${peer}-admin/tls/signcerts/* ${PWD}/organizations/fabric-ca/org${peer}/org${peer}_ca/tls/cert.pem

		#Copy the private key of rcadmin from msp/keystore to tls
		cp ${PWD}/organizations/fabric-ca/org${peer}/org${peer}_tls/ca-org${peer}-admin/tls/keystore/* ${PWD}/organizations/fabric-ca/org${peer}/org${peer}_ca/tls/key.pem
	done
	sleep 5
}


function org_createOrdererOrg() {

	export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/fabric-ca/ordererOrg/fab-ordererOrg-client
	
	#directory to store the org-ca accounts
	mkdir -p organizations/fabric-ca/ordererOrg/fab-ordererOrg-client/orderer-ca

	#Enroll the admin in org-CA
	set -x
	fabric-ca-client enroll -d -u https://rc7admin:rcadminpw@localhost:9055 --tls.certfiles tls-root-cert/tls-ca-cert.pem --csr.hosts *.example.com,localhost --mspdir orderer-ca/rcadmin/msp
	set +x
	#sleep 5

	mkdir -p organizations/ordererOrganizations
	mkdir -p organizations/ordererOrganizations/example.com
	mkdir -p organizations/ordererOrganizations/example.com/msp
	mkdir -p ${PWD}/organizations/ordererOrganizations/example.com/msp/cacerts
	mkdir -p ${PWD}/organizations/ordererOrganizations/example.com/ca
	mkdir -p ${PWD}/organizations/ordererOrganizations/example.com/tlsca
	mkdir -p ${PWD}/organizations/ordererOrganizations/example.com/msp/admincerts
	mkdir -p ${PWD}/organizations/ordererOrganizations/example.com/msp/tlscacerts

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-9055.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-9055.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-9055.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-9055.pem
    OrganizationalUnitIdentifier: orderer' > ${PWD}/organizations/ordererOrganizations/example.com/msp/config.yaml
	
	#Register an orderer in ordererOrg (Org-CA)
	for ord in 0 1 2; do
		echo "#####CREATING CRYPTO MATERIAL FOR ORDERER${ord}"
		sleep 3
		set -x
		fabric-ca-client register -d --id.name orderer${ord} --id.secret orderer${ord}pw --id.type orderer -u https://localhost:9055 --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir orderer-ca/rcadmin/msp
		set +x
		#sleep 5

		#Register an orderer in ordererOrg (TLS-CA)
		set -x
		fabric-ca-client register -d --id.name orderer${ord} --id.secret orderer${ord}pw --id.type orderer -u https://localhost:9054 --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir tls-ca/tlsadmin/msp
		set +x
		#sleep 5	


		#Enroll the Org-CA orderer
		set -x
		fabric-ca-client enroll -d -u https://orderer${ord}:orderer${ord}pw@localhost:9055 --tls.certfiles tls-root-cert/tls-ca-cert.pem --csr.hosts *.example.com,localhost --mspdir orderer-ca/orderers/orderer${ord}.example.com/msp
		set +x
		#sleep 5	

		#Enroll the TLS-CA orderer
		set -x
		fabric-ca-client enroll -d -u https://orderer${ord}:orderer${ord}pw@localhost:9054 --tls.certfiles tls-root-cert/tls-ca-cert.pem --csr.hosts *.example.com,localhost --mspdir orderer-ca/orderers/orderer${ord}.example.com/tls
		set +x
		#sleep 5

		#Make ordererOraganizations directory
		mkdir -p ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer${ord}.example.com/msp/tlscacerts
		mkdir -p ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer${ord}.example.com/msp/admincerts
		mkdir -p ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer${ord}.example.com/tls
		

		#Copy to put in appropriate format for tls
		cp ${PWD}/organizations/fabric-ca/ordererOrg/fab-ordererOrg-client/orderer-ca/orderers/orderer${ord}.example.com/tls/cacerts/* ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer${ord}.example.com/tls/ca.crt

		cp ${PWD}/organizations/fabric-ca/ordererOrg/fab-ordererOrg-client/orderer-ca/orderers/orderer${ord}.example.com/tls/signcerts/* ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer${ord}.example.com/tls/server.crt  

		cp ${PWD}/organizations/fabric-ca/ordererOrg/fab-ordererOrg-client/orderer-ca/orderers/orderer${ord}.example.com/tls/keystore/* ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer${ord}.example.com/tls/server.key

		cp -r ${PWD}/organizations/fabric-ca/ordererOrg/fab-ordererOrg-client/orderer-ca/orderers/orderer${ord}.example.com/msp/* ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer${ord}.example.com/msp

		cp -r ${PWD}/organizations/fabric-ca/ordererOrg/fab-ordererOrg-client/orderer-ca/orderers/orderer${ord}.example.com/tls/* ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer${ord}.example.com/tls

		#Copy to put in appropriate format for msp of orderer
		cp ${PWD}/organizations/fabric-ca/ordererOrg/fab-ordererOrg-client/orderer-ca/orderers/orderer${ord}.example.com/tls/cacerts/* ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer${ord}.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
	
		cp ${PWD}/organizations/ordererOrganizations/example.com/msp/config.yaml ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer${ord}.example.com/msp
	
	done

	echo "####CREATING ADMIN FOR ORDERERORG####"
	#Register admin for ordererOrg in TLS-CA
	set -x
	fabric-ca-client register -d --id.name ordOrg-admin --id.secret ordOrg-adminpw --id.type admin -u https://localhost:9054 --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir tls-ca/tlsadmin/msp
	set +x

	#Register admin for ordererOrg in orderer-ca
	set -x
	fabric-ca-client register -d --id.name ordOrg-admin --id.secret ordOrg-adminpw --id.type admin -u https://localhost:9055 --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir orderer-ca/rcadmin/msp
	set +x

	#Enroll admin for ordererOrg in orderer-ca
	set -x
	fabric-ca-client enroll -d -u https://ordOrg-admin:ordOrg-adminpw@localhost:9055 --tls.certfiles tls-root-cert/tls-ca-cert.pem --csr.hosts *.example.com,localhost --mspdir orderer-ca/users/Admin@example.com/msp
	set +x

	#Enroll admin for ordererOrg in tls-ca
	set -x
	fabric-ca-client enroll -d -u https://ordOrg-admin:ordOrg-adminpw@localhost:9054 --tls.certfiles tls-root-cert/tls-ca-cert.pem --csr.hosts *.example.com,localhost --mspdir orderer-ca/users/Admin@example.com/tls
	set +x

	#Making appropraite directories for admin@example.com
	mkdir -p ${PWD}/organizations/ordererOrganizations/example.com/users/Admin@example.com/tls
	mkdir -p ${PWD}/organizations/ordererOrganizations/example.com/users/Admin@example.com/msp/tlscacerts
	mkdir -p ${PWD}/organizations/ordererOrganizations/example.com/users/Admin@example.com/msp/admincerts

	#Copy the files to appropriate paths
	cp -r ${PWD}/organizations/fabric-ca/ordererOrg/fab-ordererOrg-client/orderer-ca/users/Admin@example.com/msp/* ${PWD}/organizations/ordererOrganizations/example.com/users/Admin@example.com/msp

	cp ${PWD}/organizations/fabric-ca/ordererOrg/fab-ordererOrg-client/orderer-ca/users/Admin@example.com/tls/cacerts/* ${PWD}/organizations/ordererOrganizations/example.com/users/Admin@example.com/tls/ca.crt

	cp ${PWD}/organizations/fabric-ca/ordererOrg/fab-ordererOrg-client/orderer-ca/users/Admin@example.com/tls/signcerts/* ${PWD}/organizations/ordererOrganizations/example.com/users/Admin@example.com/tls/server.crt  

	cp ${PWD}/organizations/fabric-ca/ordererOrg/fab-ordererOrg-client/orderer-ca/users/Admin@example.com/tls/keystore/* ${PWD}/organizations/ordererOrganizations/example.com/users/Admin@example.com/tls/server.key

	#echo "HEYYY"
	cp -r ${PWD}/organizations/fabric-ca/ordererOrg/fab-ordererOrg-client/orderer-ca/users/Admin@example.com/tls/* ${PWD}/organizations/ordererOrganizations/example.com/users/Admin@example.com/tls
	#echo "END   HEYYY"
	cp ${PWD}/organizations/fabric-ca/ordererOrg/fab-ordererOrg-client/orderer-ca/users/Admin@example.com/tls/cacerts/* ${PWD}/organizations/ordererOrganizations/example.com/users/Admin@example.com/msp/tlscacerts/tlsca.example.com-cert.pem

	cp -r ${PWD}/organizations/fabric-ca/ordererOrg/fab-ordererOrg-client/orderer-ca/users/Admin@example.com/msp/signcerts/* ${PWD}/organizations/ordererOrganizations/example.com/users/Admin@example.com/msp/admincerts/Admin@example.com-cert.pem 

	#Copying admin cert of orderer-ca to msp in all structures
	for ord in 0 1 2; do

		cp -r ${PWD}/organizations/fabric-ca/ordererOrg/fab-ordererOrg-client/orderer-ca/users/Admin@example.com/msp/signcerts/* ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer${ord}.example.com/msp/admincerts/Admin@example.com-cert.pem

	done

	cp -r ${PWD}/organizations/fabric-ca/ordererOrg/fab-ordererOrg-client/orderer-ca/users/Admin@example.com/msp/signcerts/* ${PWD}/organizations/ordererOrganizations/example.com/msp/admincerts/Admin@example.com-cert.pem

	cp -r ${PWD}/organizations/fabric-ca/ordererOrg/fab-ordererOrg-client/orderer-ca/users/Admin@example.com/msp/cacerts/* ${PWD}/organizations/ordererOrganizations/example.com/msp/cacerts

	cp -r ${PWD}/organizations/fabric-ca/ordererOrg/fab-ordererOrg-client/orderer-ca/users/Admin@example.com/tls/cacerts/* ${PWD}/organizations/ordererOrganizations/example.com/msp/tlscacerts/tlsca.example.com-cert.pem

	cp ${PWD}/organizations/ordererOrganizations/example.com/msp/config.yaml ${PWD}/organizations/ordererOrganizations/example.com/users/Admin@example.com/msp

	#Forming the ca and tlsca for ordererOrg
	cp -r ${PWD}/organizations/fabric-ca/ordererOrg/fab-ordererOrg-client/tls-ca/rcadmin/msp/* ${PWD}/organizations/ordererOrganizations/example.com/tlsca

	#cp ${PWD}/organizations/fabric-ca/ordererOrg/fab-ordererOrg-client/tls-ca/rcadmin/msp/keystore/* ${PWD}/organizations/ordererOrganizations/example.com/tlsca/priv_sk

	cp -r ${PWD}/organizations/fabric-ca/ordererOrg/fab-ordererOrg-client/orderer-ca/rcadmin/msp/* ${PWD}/organizations/ordererOrganizations/example.com/ca

#cp ${PWD}/organizations/fabric-ca/ordererOrg/fab-ordererOrg-client/orderer-ca/rcadmin/msp/keystore/* ${PWD}/organizations/ordererOrganizations/example.com/ca/priv_sk
}

function orgca_createPeerOrgs() {
	export FABRIC_CA_CLIENT_HOME=${PWD}
	
	mkdir -p organizations/peerOrganizations/org1.example.com/msp
	echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-7054.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-7054.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-7054.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-7054.pem
    OrganizationalUnitIdentifier: orderer' > ${PWD}/organizations/peerOrganizations/org1.example.com/msp/config.yaml
    
    mkdir -p organizations/peerOrganizations/org2.example.com/msp
	echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-8054.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-8054.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-8054.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-8054.pem
    OrganizationalUnitIdentifier: orderer' > ${PWD}/organizations/peerOrganizations/org2.example.com/msp/config.yaml
    
	echo "Enrolling ORG_CA admins"
  	sleep 5
	#enroll ca-org1 admin 
  	fabric-ca-client enroll -d -u https://ca-org1-admin:ca-org1-adminpw@localhost:7054 --csr.hosts *.example.com,localhost --mspdir organizations/fabric-ca/org1/org1_ca/admin/ca --tls.certfiles organizations/fabric-ca/org1/org1_tls/ca-cert.pem #--csr.hosts *.example.com,localhost --mspdir organizations/fabric-ca/org1/org1_ca/admin/ca
	
	sleep 5
  	#enroll ca-org2 admin 
  	fabric-ca-client enroll -d -u https://ca-org2-admin:ca-org2-adminpw@localhost:8054 --tls.certfiles organizations/fabric-ca/org2/org2_tls/ca-cert.pem --csr.hosts *.example.com,localhost --mspdir organizations/fabric-ca/org2/org2_ca/admin/ca

	echo "ORG_CA SUCCESSFUL"
	sleep 5
  

	echo "#####CYRPTO FOR ORG1 & ORG2(PEERS)######"
	sleep 5
  #register peer0-org1 to tls ca of org1
  fabric-ca-client register -d --id.name peer0-org1 --id.secret peer0org1PW --id.type peer -u https://localhost:7052 --tls.certfiles organizations/fabric-ca/org1/org1_tls/ca-cert.pem --mspdir organizations/fabric-ca/org1/org1_tls/admin/tlsca
	
	#register peer0-org1 to org1 ca
  fabric-ca-client register -d --id.name peer0-org1 --id.secret peer0org1PW --id.type peer -u https://localhost:7054 --tls.certfiles organizations/fabric-ca/org1/org1_tls/ca-cert.pem --mspdir organizations/fabric-ca/org1/org1_ca/admin/ca

echo "####
 	####
 	####"
 	sleep 5
 	
  #enroll peer0-org1 to org1 ca
  fabric-ca-client enroll -d -u https://peer0-org1:peer0org1PW@localhost:7054 --tls.certfiles organizations/fabric-ca/org1/org1_tls/ca-cert.pem --csr.hosts *.org1.example.com,localhost --mspdir organizations/fabric-ca/org1/org1_ca/peer0-org1/msp

echo "####
 	####
 	####"
 	sleep 5
 	
  #enroll peer0-org1 to tls ca of org1 
  fabric-ca-client enroll -d -u https://peer0-org1:peer0org1PW@localhost:7052 --tls.certfiles organizations/fabric-ca/org1/org1_tls/ca-cert.pem --csr.hosts *.org1.example.com,localhost --mspdir organizations/fabric-ca/org1/org1_tls/peer0-org1/tls

  #register peer0-org2 to tls ca of org2
  fabric-ca-client register -d --id.name peer0-org2 --id.secret peer0org2PW --id.type peer -u https://localhost:8052 --tls.certfiles organizations/fabric-ca/org2/org2_tls/ca-cert.pem --mspdir organizations/fabric-ca/org2/org2_tls/admin/tlsca

	#register peer0-org2 to org2 ca
  fabric-ca-client register -d --id.name peer0-org2 --id.secret peer0org2PW --id.type peer -u https://localhost:8054 --tls.certfiles organizations/fabric-ca/org2/org2_tls/ca-cert.pem --mspdir organizations/fabric-ca/org2/org2_ca/admin/ca

echo "####
 	####
 	####"
 	sleep 5
 	
  #enroll peer0-org2 to org2 ca
  fabric-ca-client enroll -d -u https://peer0-org2:peer0org2PW@localhost:8054 --tls.certfiles organizations/fabric-ca/org2/org2_tls/ca-cert.pem --csr.hosts *.org2.example.com,localhost --mspdir organizations/fabric-ca/org2/org2_ca/peer0-org2/msp
  echo "####
 	####
 	####"
 	sleep 5
  #enroll peer0-org2 to tls ca of org2 
  fabric-ca-client enroll -d -u https://peer0-org2:peer0org2PW@localhost:8052 --tls.certfiles organizations/fabric-ca/org2/org2_tls/ca-cert.pem --csr.hosts *.org2.example.com,localhost --mspdir organizations/fabric-ca/org2/org2_tls/peer0-org2/tls

echo "####
 	####
 	####"
 	sleep 5
  
 	  echo "####CRYPTO FOR ORG1(USERS)#####"
	#sleep 5
	#register org1admin to tls ca of org1
  fabric-ca-client register -d --id.name org1admin --id.secret org1adminPW --id.type admin -u https://localhost:7052 --tls.certfiles organizations/fabric-ca/org1/org1_tls/ca-cert.pem --mspdir organizations/fabric-ca/org1/org1_tls/admin/tlsca
 
 #register org1admin to org1 ca
    echo "WATCH THIS"
    sleep 5
  fabric-ca-client register -d --id.name org1admin --id.secret org1adminPW --id.type admin -u https://localhost:7054 --tls.certfiles organizations/fabric-ca/org1/org1_tls/ca-cert.pem --mspdir organizations/fabric-ca/org1/org1_ca/admin/ca
 	echo "####
 	####
 	####"
 	#sleep 5
   echo "WATCH THIS"
   sleep 5
  fabric-ca-client enroll -u https://org1admin:org1adminPW@localhost:7054 --tls.certfiles organizations/fabric-ca/org1/org1_tls/ca-cert.pem --csr.hosts *.example.com,localhost --mspdir organizations/fabric-ca/org1/org1_ca/org1admin/msp
 	echo "####
 	####
 	####"
 	sleep 5
 	
  #enroll org1admin to tls ca of org1 
  fabric-ca-client enroll -d -u https://org1admin:org1adminPW@localhost:7052 --tls.certfiles organizations/fabric-ca/org1/org1_tls/ca-cert.pem --csr.hosts *.org1.example.com,localhost --mspdir organizations/fabric-ca/org1/org1_tls/org1admin/tls

	echo "####
 	####
 	####"
 	sleep 5
 	
  #register user1 to tls ca of org1
  fabric-ca-client register -d --id.name user1 --id.secret user1PW --id.type client -u https://localhost:7052 --tls.certfiles organizations/fabric-ca/org1/org1_tls/ca-cert.pem --mspdir organizations/fabric-ca/org1/org1_tls/admin/tlsca
 
 #register user1 to org1 ca
  fabric-ca-client register -d --id.name user1 --id.secret user1PW --id.type client -u https://localhost:7054 --tls.certfiles organizations/fabric-ca/org1/org1_tls/ca-cert.pem --mspdir organizations/fabric-ca/org1/org1_ca/admin/ca
  echo "####
 	####
 	####"
 	#sleep 5
  fabric-ca-client enroll -u https://user1:user1PW@localhost:7054 --tls.certfiles organizations/fabric-ca/org1/org1_tls/ca-cert.pem --csr.hosts *.org1.example.com,localhost --mspdir organizations/fabric-ca/org1/org1_ca/user1/msp
  echo "####
 	####
 	####"
 	sleep 5
  #enroll user1 to tls ca of org1 
  fabric-ca-client enroll -d -u https://user1:user1PW@localhost:7052 --tls.certfiles organizations/fabric-ca/org1/org1_tls/ca-cert.pem --csr.hosts *.org1.example.com,localhost --mspdir organizations/fabric-ca/org1/org1_tls/user1/tls
 	
  

	echo "#####CYRPTO FOR ORG2(USERS)######"
	sleep 5
  #register org2admin to tls ca of org2
  fabric-ca-client register -d --id.name org2admin --id.secret org2adminPW --id.type admin -u https://localhost:8052 --tls.certfiles organizations/fabric-ca/org2/org2_tls/ca-cert.pem --mspdir organizations/fabric-ca/org2/org2_tls/admin/tlsca
 
 #register org2admin to org2 ca
  fabric-ca-client register -d --id.name org2admin --id.secret org2adminPW --id.type admin -u https://localhost:8054 --tls.certfiles organizations/fabric-ca/org2/org2_tls/ca-cert.pem --mspdir organizations/fabric-ca/org2/org2_ca/admin/ca
 echo "####
 	####
 	####"
 	#sleep 5
  fabric-ca-client enroll -u https://org2admin:org2adminPW@localhost:8054 --tls.certfiles organizations/fabric-ca/org2/org2_tls/ca-cert.pem --csr.hosts *.org2.example.com,localhost --mspdir organizations/fabric-ca/org2/org2_ca/org2admin/msp
echo "####
 	####
 	####"
 	sleep 5
  #enroll org2admin to tls ca of org2 
  fabric-ca-client enroll -d -u https://org2admin:org2adminPW@localhost:8052 --tls.certfiles organizations/fabric-ca/org2/org2_tls/ca-cert.pem --csr.hosts *.org2.example.com,localhost --mspdir organizations/fabric-ca/org2/org2_tls/org2admin/tls

  #register user1 to tls ca of org2
  fabric-ca-client register -d --id.name user1 --id.secret user1PW --id.type client -u https://localhost:8052 --tls.certfiles organizations/fabric-ca/org2/org2_tls/ca-cert.pem --mspdir organizations/fabric-ca/org2/org2_tls/admin/tlsca
 
 #register user1 to org2 ca
  fabric-ca-client register -d --id.name user1 --id.secret user1PW --id.type client -u https://localhost:8054 --tls.certfiles organizations/fabric-ca/org2/org2_tls/ca-cert.pem --mspdir organizations/fabric-ca/org2/org2_ca/admin/ca
  
  echo "####
 	####
 	####"
 	sleep 5
 	
  fabric-ca-client enroll -u https://user1:user1PW@localhost:8054 --tls.certfiles organizations/fabric-ca/org2/org2_tls/ca-cert.pem --csr.hosts *.org2.example.com,localhost --mspdir organizations/fabric-ca/org2/org2_ca/user1/msp
  
  #enroll user1 to tls ca of org2 
  fabric-ca-client enroll -d -u https://user1:user1PW@localhost:8052 --tls.certfiles organizations/fabric-ca/org2/org2_tls/ca-cert.pem --csr.hosts *.org2.example.com,localhost --mspdir organizations/fabric-ca/org2/org2_tls/user1/tls

  


	echo "MAKING APPROPRIATE STRUCTURE!!!"
	sleep 5
	for peer in 1 2; do
  		mkdir -p organizations/peerOrganizations/org${peer}.example.com/msp
  		mkdir -p organizations/peerOrganizations/org${peer}.example.com/ca
  		mkdir -p organizations/peerOrganizations/org${peer}.example.com/tlsca
  		mkdir -p organizations/peerOrganizations/org${peer}.example.com/users
  		mkdir -p organizations/peerOrganizations/org${peer}.example.com/peers
  		mkdir -p organizations/peerOrganizations/org${peer}.example.com/msp/cacerts
  		mkdir -p organizations/peerOrganizations/org${peer}.example.com/msp/tlscacerts
  		mkdir -p organizations/peerOrganizations/org${peer}.example.com/msp/admincerts
  		mkdir -p organizations/peerOrganizations/org${peer}.example.com/peers/peer0.org${peer}.example.com
  		mkdir -p organizations/peerOrganizations/org${peer}.example.com/peers/peer0.org${peer}.example.com/msp
  		mkdir -p organizations/peerOrganizations/org${peer}.example.com/peers/peer0.org${peer}.example.com/msp/cacerts
  		mkdir -p organizations/peerOrganizations/org${peer}.example.com/peers/peer0.org${peer}.example.com/msp/tlscacerts
  		mkdir -p organizations/peerOrganizations/org${peer}.example.com/peers/peer0.org${peer}.example.com/msp/admincerts
  		mkdir -p organizations/peerOrganizations/org${peer}.example.com/peers/peer0.org${peer}.example.com/tls
		mkdir -p organizations/peerOrganizations/org${peer}.example.com/users/Admin@org${peer}.example.com
		mkdir -p organizations/peerOrganizations/org${peer}.example.com/users/Admin@org${peer}.example.com/msp
		mkdir -p organizations/peerOrganizations/org${peer}.example.com/users/Admin@org${peer}.example.com/tls
		mkdir -p organizations/peerOrganizations/org${peer}.example.com/users/Admin@org${peer}.example.com/msp/admincerts
		mkdir -p organizations/peerOrganizations/org${peer}.example.com/users/Admin@org${peer}.example.com/msp/tlscacerts
		mkdir -p organizations/peerOrganizations/org${peer}.example.com/users/User1@org${peer}.example.com
		mkdir -p organizations/peerOrganizations/org${peer}.example.com/users/User1@org${peer}.example.com/msp
		mkdir -p organizations/peerOrganizations/org${peer}.example.com/users/User1@org${peer}.example.com/tls
		mkdir -p organizations/peerOrganizations/org${peer}.example.com/users/User1@org${peer}.example.com/msp/admincerts
		mkdir -p organizations/peerOrganizations/org${peer}.example.com/users/User1@org${peer}.example.com/msp/tlscacerts
	done
	
  cp ${PWD}/organizations/fabric-ca/org1/org1_ca/admin/ca/cacerts/* ${PWD}/organizations/peerOrganizations/org1.example.com/msp/cacerts

  cp ${PWD}/organizations/peerOrganizations/org1.example.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp/config.yaml
  
  cp ${PWD}/organizations/peerOrganizations/org2.example.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/msp/config.yaml 
  
  #mkdir -p organizations/peerOrganizations/org1.example.com/msp/tlscacerts
  cp -r ${PWD}/organizations/fabric-ca/org1/org1_tls/admin/tlsca/cacerts/* ${PWD}/organizations/peerOrganizations/org1.example.com/msp/tlscacerts
  #mkdir -p organizations/peerOrganizations/org1.example.com/msp/admincerts

  cp -r ${PWD}/organizations/fabric-ca/org1/org1_tls/admin/* ${PWD}/organizations/peerOrganizations/org1.example.com
  cp -r ${PWD}/organizations/fabric-ca/org1/org1_ca/admin/* ${PWD}/organizations/peerOrganizations/org1.example.com

  cp  -r ${PWD}/organizations/fabric-ca/org1/org1_ca/peer0-org1/msp/* ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp
  cp -r ${PWD}/organizations/fabric-ca/org1/org1_tls/peer0-org1/tls/* ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls
  cp -r ${PWD}/organizations/fabric-ca/org1/org1_tls/peer0-org1/tls/cacerts/* ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
  cp -r ${PWD}/organizations/fabric-ca/org1/org1_tls/peer0-org1/tls/signcerts/* ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.crt
  cp -r ${PWD}/organizations/fabric-ca/org1/org1_tls/peer0-org1/tls/keystore/* ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.key

  

  #mkdir -p organizations/peerOrganizations/org1.example.com/users
  #mkdir -p organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com
  #mkdir -p organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com
  # mkdir -p organizations/peerOrganizations/org1.example.com/msp/admincerts
  # mkdir -p organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp/admincerts
   #mkdir -p organizations/peerOrganizations/org2.example.com/peer0.org2.example.com/msp/admincerts
   # mkdir -p organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/msp/admincerts
   # mkdir -p organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp/tlscacerts
   #     mkdir -p organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/msp/tlscacerts
   

  cp  -r ${PWD}/organizations/fabric-ca/org1/org1_ca/org1admin/* ${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com
  cp -r ${PWD}/organizations/fabric-ca/org1/org1_tls/org1admin/* ${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com

  cp  -r ${PWD}/organizations/fabric-ca/org1/org1_ca/user1/* ${PWD}/organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com
  cp -r ${PWD}/organizations/fabric-ca/org1/org1_tls/user1/* ${PWD}/organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com

	cp -r ${PWD}/organizations/fabric-ca/org1/org1_tls/user1/tls/cacerts/* ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp/tlscacerts/tlsca.org1.example.com-cert.pem
	
	cp -r ${PWD}/organizations/fabric-ca/org2/org2_tls/user1/tls/cacerts/* ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/msp/tlscacerts/tlsca.org2.example.com-cert.pem


  #mkdir -p organizations/peerOrganizations/org2.example.com/msp
   #mkdir -p organizations/peerOrganizations/org2.example.com/msp/admincerts
###   
   #mkdir -p organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp/admincerts
   #mkdir -p organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/admincerts
   #mkdir -p organizations/peerOrganizations/org2.example.com/users/User1@org2.example.com/msp/admincerts
	#mkdir -p organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp/admincerts

  cp  -r ${PWD}/organizations/fabric-ca/org2/org2_ca/admin/ca/cacerts/* ${PWD}/organizations/peerOrganizations/org2.example.com/msp/cacerts

 # mkdir -p organizations/peerOrganizations/org2.example.com/msp/tlscacerts
  cp -r ${PWD}/organizations/fabric-ca/org2/org2_tls/admin/tlsca/cacerts/* ${PWD}/organizations/peerOrganizations/org2.example.com/msp/tlscacerts
  #mkdir -p organizations/peerOrganizations/org2.example.com/msp/admincerts

  cp -r ${PWD}/organizations/fabric-ca/org2/org2_tls/admin/* ${PWD}/organizations/peerOrganizations/org2.example.com
  cp -r ${PWD}/organizations/fabric-ca/org2/org2_ca/admin/* ${PWD}/organizations/peerOrganizations/org2.example.com

  cp  -r ${PWD}/organizations/fabric-ca/org2/org2_ca/peer0-org2/msp/* ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/msp
  cp -r ${PWD}/organizations/fabric-ca/org2/org2_tls/peer0-org2/tls/* ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls
  cp -r ${PWD}/organizations/fabric-ca/org2/org2_tls/peer0-org2/tls/cacerts/* ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
  cp -r ${PWD}/organizations/fabric-ca/org2/org2_tls/peer0-org2/tls/signcerts/* ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/server.crt
  cp -r ${PWD}/organizations/fabric-ca/org2/org2_tls/peer0-org2/tls/keystore/* ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/server.key

  

  #mkdir -p organizations/peerOrganizations/org2.example.com/users
  #mkdir -p organizations/peerOrganizations/org2.example.com/users/User1@org2.example.com/msp/tlscacerts
  #mkdir -p organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp/tlscacerts
  #mkdir -p organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp/tlscacerts
  #mkdir -p organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/tlscacerts

  cp  -r ${PWD}/organizations/fabric-ca/org2/org2_ca/org2admin/* ${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com
  cp -r ${PWD}/organizations/fabric-ca/org2/org2_tls/org2admin/* ${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com
##
	cp -r ${PWD}/organizations/fabric-ca/org2/org2_tls/peer0-org2/tls/cacerts/* ${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp/tlscacerts/tlsca.org2.example.com
	cp -r ${PWD}/organizations/fabric-ca/org2/org2_tls/peer0-org2/tls/cacerts/* ${PWD}/organizations/peerOrganizations/org2.example.com/users/User1@org2.example.com/msp/tlscacerts/tlsca.org2.example.com

##
	cp -r ${PWD}/organizations/fabric-ca/org1/org1_tls/org1admin/tls/cacerts/* ${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/tlscacerts/tlsca.org1.example.com
	cp -r ${PWD}/organizations/fabric-ca/org1/org1_tls/org1admin/tls/cacerts/* ${PWD}/organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp/tlscacerts/tlsca.org1.example.com
	
	
  cp  -r ${PWD}/organizations/fabric-ca/org2/org2_ca/user1/* ${PWD}/organizations/peerOrganizations/org2.example.com/users/User1@org2.example.com
  cp -r ${PWD}/organizations/fabric-ca/org2/org2_tls/user1/* ${PWD}/organizations/peerOrganizations/org2.example.com/users/User1@org2.example.com

	cp ${PWD}/organizations/peerOrganizations/org1.example.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/config.yaml
	
	cp ${PWD}/organizations/peerOrganizations/org1.example.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp/config.yaml

	cp ${PWD}/organizations/peerOrganizations/org2.example.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/org2.example.com/users/User1@org2.example.com/msp/config.yaml
	
	cp ${PWD}/organizations/peerOrganizations/org2.example.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp/config.yaml
	
	
	echo "ASSIGNING TLS"
	sleep 3
	for peer in 1 2; do
	cp -r ${PWD}/organizations/fabric-ca/org${peer}/org${peer}_tls/user1/tls/cacerts/* ${PWD}/organizations/peerOrganizations/org${peer}.example.com/users/User1@org${peer}.example.com/tls/ca.crt
	
	cp -r ${PWD}/organizations/fabric-ca/org${peer}/org${peer}_tls/user1/tls/signcerts/* ${PWD}/organizations/peerOrganizations/org${peer}.example.com/users/User1@org${peer}.example.com/tls/client.crt
	
	cp -r ${PWD}/organizations/fabric-ca/org${peer}/org${peer}_tls/user1/tls/keystore/* ${PWD}/organizations/peerOrganizations/org${peer}.example.com/users/User1@org${peer}.example.com/tls/client.key
	
	cp -r ${PWD}/organizations/fabric-ca/org${peer}/org${peer}_tls/org${peer}admin/tls/cacerts/* ${PWD}/organizations/peerOrganizations/org${peer}.example.com/users/Admin@org${peer}.example.com/tls/ca.crt 
	
	cp -r ${PWD}/organizations/fabric-ca/org${peer}/org${peer}_tls/org${peer}admin/tls/signcerts/* ${PWD}/organizations/peerOrganizations/org${peer}.example.com/users/Admin@org${peer}.example.com/tls/client.crt 
	
	cp -r ${PWD}/organizations/fabric-ca/org${peer}/org${peer}_tls/org${peer}admin/tls/keystore/* ${PWD}/organizations/peerOrganizations/org${peer}.example.com/users/Admin@org${peer}.example.com/tls/client.key
	
	done
	echo "PEERORG HAS BEEN ASSIGNED WITH PROPER CERTS"
	sleep 5	
}




#set -x
#cryptogen generate --config=./crypto-config.yaml --output="organizations"
#res=$?
#set +x
#if [ $res -ne 0 ]; then
#	echo "Failed to generate certs"
#	exit 1
#fi

#echo "CRYPTO FOR ORGS GENERATED"
#sleep 3

#which configtxgen
#if [ "$?" -ne 0 ]; then
#	echo "CONFIGTXGEN missing!!"
#	exit 1#
#	fi

	#echo "Generating Orderer genesis block"
	#sleep 3
	#set -x
	#configtxgen -profile SampleMultiNodeEtcdRaft -channelID barterx-sys-channel -outputBlock ./channel-artifacts/genesis.block
	#sleep 3
	#res=$?
	#set +x
	#if [ $res -ne 0 ]; then
	#	echo "Failed genesis block!!"
	#	exit 1
	#fi	

	#echo "Bringing up docker orderers containers!!"
	#sleep 5
	#
	#DOCKER_COMPOSE_ORDERER_FILE=docker-compose-orderers.yaml
	#
	#DOCKER_FILES="-f ${DOCKER_COMPOSE_ORDERER_FILE}"
	#
	#IMAGE_TAG=$IMAGETAG docker-compose ${DOCKER_FILES} up -d 2>&1
	#
	#docker ps -a
	#if [ $? -ne 0 ]; then
	#	echo "ERROR!!!!! ORDERERS!!!!!"
	#	exit 1
	#fi

	#echo "STARTED ORDERERS"

	#sleep 5
#}
