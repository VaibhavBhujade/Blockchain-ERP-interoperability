package main

import (
	"encoding/json"
	// "errors"
	"fmt"
	// "strconv"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

func main() {

	chaincode, err := contractapi.NewChaincode(new(TransactionContract))

	if err != nil {
		fmt.Printf("Error create transaction chaincode: %s", err.Error())
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting transaction chaincode: %s", err.Error())
	}
}


type TransactionContract struct {
	contractapi.Contract
}

type Transaction struct {
	Product_Code  string `json:"prod_code"`
	Quantity string `json:"qnty"`
	Price  string `json:"prod_price"`
    Product_Name string `json:"prod_name"`
    Batch_ID string `json:"batch"`
    Unit string `json:"prod_unit"`
    Total_Amount string `json:"prod_amount"`
    Expected_Delivery string `json:"ex_date"`
    EID_Buyer string `json:"buyer_eid"`
    Promise_Delivery string `json:"pr_date"`
    EID_Seller string `json:"seller_eid"`
    // Prev_txID string
}

type QueryResult struct {
	Key    string `json:"Key"`
	Record *Transaction
}

func (tc *TransactionContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	return nil
}

func (tc *TransactionContract) Create(ctx contractapi.TransactionContextInterface, tx_id string, prod_code string, qnty string, prod_price string, prod_name string, batch string, prod_unit string, prod_amount string, ex_date string, buyer_eid string, pr_date string, seller_eid string) error {

	transaction := Transaction{
				Product_Code: prod_code,
				Quantity: qnty,
				Price: prod_price,
				Product_Name: prod_name,
				Batch_ID: batch,
				Unit: prod_unit,
				Total_Amount: prod_amount,
				Expected_Delivery: ex_date,
				EID_Buyer: buyer_eid,
				Promise_Delivery: pr_date,
				EID_Seller: seller_eid,
	}
	txAsBytes, _ := json.Marshal(transaction)

	return ctx.GetStub().PutState(tx_id, txAsBytes)

}

func (tc *TransactionContract) Query_Tx(ctx contractapi.TransactionContextInterface, tx_id string) (*Transaction, error) {
	txAsBytes, err := ctx.GetStub().GetState(tx_id)

	if err != nil {
		return nil, fmt.Errorf("Failed to read from world state. %s", err.Error())
	}

	if txAsBytes == nil {
		return nil, fmt.Errorf("%s does not exist", tx_id)
	}

	transaction := new(Transaction)
	_ = json.Unmarshal(txAsBytes, transaction)

	return transaction, nil
}


// func Query_Tx(ctx contractapi.TransactionContextInterface, tx_id string) (string, error) {
// 	existing, err := ctx.GetStub().GetState(tx_id)

// 	if err != nil {
// 		return "", errors.New("Unable to interact with world state")
// 	}

// 	if existing == nil {
// 		return "", fmt.Errorf("Cannot read world state pair with key %s. Does not exist", key)
// 	}

// 	return string(existing), nil
// }
func (tc *TransactionContract) QueryAll(ctx contractapi.TransactionContextInterface) ([]QueryResult, error) {
	startKey := "tx0"
	endKey := "tx100"

	resultsIterator, err := ctx.GetStub().GetStateByRange(startKey, endKey)

	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	results := []QueryResult{}

	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()

		if err != nil {
			return nil, err
		}

		transaction := new(Transaction) 
		_ = json.Unmarshal(queryResponse.Value, transaction)

		queryResult := QueryResult{Key: queryResponse.Key, Record: transaction}
		results = append(results, queryResult)
	}

	return results, nil
}
