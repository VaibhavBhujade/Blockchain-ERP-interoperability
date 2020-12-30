#!/bin/bash

#export FABRIC_CFG_PATH=${PWD}/..:${PWD}

#Function to create a channel
function createChannel() {
	echo "CHANNEL NAME : "$CHANNEL_NAME
	echo $FABRIC_CFG_PATH 
	sleep 3
	
	set -x
	
	#configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME
	#>&log.txt
	res=$?
	set +x
	
	if [ $? -ne 0 ]; then
		echo "Channel create failed!!"
	fi
	echo "Channel TX created successfully in $CHANNEL_NAME.tx"
	
	echo "Generating block for the given channel name"
	sleep 3
	
	set -x
	peer channel create -o orderer0.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls --cafile /etc/hyperledger/orderers/msp/tlscacerts/tlsca.example.com-cert.pem
	res=$?
	set +x
	if [ $? -ne 0 ]; then
		echo "FAILED to create channel!!"
	fi 
	
	echo "CHANNEL : $CHANNEL_NAME CREATED SUCCESSFULLY!!"
	sleep 3
}

#Function to join a channel
function joinChannel() {
	#Joining a peer selected given channel
	peer channel join -b ${CHANNEL_NAME}.block
}

#Default variables declaration
CHANNEL_NAME="demochannel"


if [[ $# -lt 1 ]]; then
	exit 0
else
	MODE=$1
	shift
fi

while getopts "h?c:t:d:s:l:i:anv" opt; do
	case "$opt" in
	h | \?)
		echo "Help documentation under process...something went wrong"
		exit 0;
		;;
	c)
		CHANNEL_NAME=$OPTARG
		;;
	v)
		VERBOSE=true
		;;
	esac
done 

if [ "$MODE" = "join" ]; then
	joinChannel
elif [ "$MODE" = "create" ]; then
	createChannel
fi
