

'use strict';
var os = require('os');
//import {getDataToHash} from './generateSign.js';
const generateSign =require('./generateSign.js');

async function main(received) {
    try {
        const { KJUR, KEYUTIL } = require('jsrsasign');
        const CryptoJS = require('crypto-js');    
        const { Gateway, Wallets } = require('fabric-network');
        const fs = require('fs');
        const path = require('path');
        // load the network configuration
        var osname;
        if(os.type()=='Windows_NT')
            osname='windows';
        else
            osname='linux';

        const ccpPath = path.resolve(__dirname, '..','1st_prototype_'+osname, 'organizations', 'peerOrganizations', received.org+'.example.com', 'connection-'+received.org+'.json');
        let ccp = JSON.parse(fs.readFileSync(ccpPath, 'utf8'));

        // Create a new file system based wallet for managing identities.
        const walletPath = path.join(process.cwd(), 'wallet');
        const wallet = await Wallets.newFileSystemWallet(walletPath);
        console.log(`Wallet path: ${walletPath}`);

        // Check to see if we've already enrolled the user.
        const identity = await wallet.get(received.userid);
        if (!identity) {
            console.log('An identity for the user '+received.userid+' does not exist in the wallet');
            console.log('Run the registerUser.js application before retrying');
            return;
        }

        const walletContents = await wallet.get(received.userid);

        //get data to hash 
        var transaction_string = await generateSign.getDataToHash(received);
        
        //hash the transaction data
        var hashToAction =  await generateSign.calculateHash(transaction_string) 
        console.log("Hash of the file: " + hashToAction);

        //Get signature and public key of received object user
        var sigValueBase64 = received.signature1;
        var publicKey1 = received.publicKey1;

        // get certificate from the certfile
        const certLoaded = walletContents.credentials.certificate;

        
        var userPublicKey = KEYUTIL.getKey(publicKey1);
        var recover = new KJUR.crypto.Signature({"alg": "SHA256withECDSA"});
        recover.init(userPublicKey);
        recover.updateHex(hashToAction);
        var getBackSigValueHex = new Buffer.from(sigValueBase64, 'base64').toString('hex');
        //Check if correct
        if (recover.verify(getBackSigValueHex) != true) {
            throw new Error('Signature does not match!!');
        }
        console.log("Signature verified with certificate provided: " + recover.verify(getBackSigValueHex));

        //Signature of user 2
        var transaction_string_with_two_signatures = await generateSign.getDataToHashWithSignature(received);
        var finalHash = await generateSign.calculateHash(transaction_string_with_two_signatures);
        //Sign it with private key!! 
        //_____TODO_____CHANGE THE USERID and ORG FOR SECOND SIGNATURE!!!
        var finalSignature = await generateSign.signDocument(finalHash, received.userid, received.org);
        console.log("Final Signature"+ finalSignature);

        // Create a new gateway for connecting to our peer node.
        const gateway = new Gateway();
        await gateway.connect(ccp, { wallet, identity: received.userid, discovery: { enabled: true, asLocalhost: true } });

        // Get the network (channel) our contract is deployed to.
        const network = await gateway.getNetwork('demochannel');

        // Get the contract from the network.
        const contract = network.getContract('transactionv1');

        var key_ex = received.transactionID;
        var pname_ex = received.product_name;
        var pcode_ex = received.product_code;
        var q_ex = received.quantity;
        var unit_ex = received.quantity_unit;
        var price_ex = received.price;
        var batch_ex = "100";
        var amount_ex = received.amount;
        var del_ex = received.expected_delivery;
        var buyer_ex = received.eid_buyer;
        var pdel_ex = received.promise_delivery;
        var seller_ex = received.eid_seller;
        var prev_ex= received.prev_transactions;
        await contract.submitTransaction('Create', key_ex, pcode_ex, q_ex, price_ex, pname_ex, batch_ex, unit_ex, amount_ex, del_ex, buyer_ex, pdel_ex, seller_ex, prev_ex);
        
        console.log('Transaction has been submitted');
        //return true;
        // Disconnect from the gateway.
        await gateway.disconnect();

    } catch (error) {
        console.error(`Failed to submit transaction: ${error}`);
        //return false;
        process.exit(1);
    }
}

//main();
module.exports={main};