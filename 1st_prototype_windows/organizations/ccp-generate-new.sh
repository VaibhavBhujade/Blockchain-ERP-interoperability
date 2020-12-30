#!/bin/bash

function one_line_pem {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
}

function json_ccp {
    local PP=$(one_line_pem $5)
    local CP=$(one_line_pem $6)
    local TP=$(one_line_pem $7)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s/\${TLSCAPORT}/$4/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        -e "s#\${TLSCAPEM}#$TP#" \
        organizations/ccp-template-new.json
}

function yaml_ccp {
    local PP=$(one_line_pem $5)
    local CP=$(one_line_pem $6)
    local TP=$(one_line_pem $7)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s/\${TLSCAPORT}/$4/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        -e "s#\${TLSCAPEM}#$TP#" \
        organizations/ccp-template-new.yaml | sed -e $'s/\\\\n/\\\n          /g'
}

ORG=1
P0PORT=7051
CAPORT=7054
TLSCAPORT=7052
PEERPEM=organizations/peerOrganizations/org1.example.com/tlsca/cacerts/localhost-7052.pem 
CAPEM=organizations/peerOrganizations/org1.example.com/ca/cacerts/localhost-7054.pem
TLSCAPEM=organizations/peerOrganizations/org1.example.com/tlsca/cacerts/localhost-7052.pem 

echo "$(json_ccp $ORG $P0PORT $CAPORT $TLSCAPORT $PEERPEM $CAPEM $TLSCAPEM)" > organizations/peerOrganizations/org1.example.com/connection-org1.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $TLSCAPORT $PEERPEM $CAPEM $TLSCAPEM)" > organizations/peerOrganizations/org1.example.com/connection-org1.yaml

ORG=2
P0PORT=9051
CAPORT=8054
TLSCAPORT=8052
PEERPEM=organizations/peerOrganizations/org2.example.com/tlsca/cacerts/localhost-8052.pem
CAPEM=organizations/peerOrganizations/org2.example.com/ca/cacerts/localhost-8054.pem
TLSCAPEM=organizations/peerOrganizations/org2.example.com/tlsca/cacerts/localhost-8052.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $TLSCAPORT $PEERPEM $CAPEM $TLSCAPEM)" > organizations/peerOrganizations/org2.example.com/connection-org2.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $TLSCAPORT $PEERPEM $CAPEM $TLSCAPEM)" > organizations/peerOrganizations/org2.example.com/connection-org2.yaml
