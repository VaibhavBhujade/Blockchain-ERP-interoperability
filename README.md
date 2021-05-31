# Blockchain-ERP-interoperability

## Contents of this file

* Introduction
* Setup
* Tech Stack
* Contributers

## Introduction


## Setup

To built transaction folder (Only for new users)
```bash
	GO111MODULE=on go mod vendor
```
For bringing the network up

```bash
./start_network.sh up

./organizations/ccp-generate-new.sh
```
 
Copy transactionv1 folder in 1st_prototype/chaincode

```bash
bash CCNAME-gen.sh
```

Debugging -

To remove existing wallets
```bash
rm -rf wallet*
```

For bringing the network down
```bash
./start_network.sh down

docker ps -aq

docker network prune

docker volume prune
```

## Tech Stack
* Hyperledger Fabric
* Odoo ERP
* NodeJS

## Contributors
* [VaibhavBhujade](https://github.com/VaibhavBhujade)
* [Aakanksha2810](https://github.com/Aakanksha2810)
* [shreyzo](https://github.com/shreyzo)
