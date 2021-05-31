
'use strict';
var os = require('os');
var signature_string;

async function calculateHash(data) {
    try {
        const CryptoJS = require('crypto-js');
        var hashToAction = CryptoJS.SHA256(data).toString();
        return await hashToAction;
    }
    catch {
        console.log("Exception occured");
    }
}

async function getDataToHash(received) {
    try {
        var transaction_details = {
            key_ex : received.transactionID,
            pcode_ex : received.product_code,
            q_ex :received.quantity,
            price_ex : received.price,
            pname_ex :received.product_name,
            batch_ex : "100",
            unit_ex : received.quantity_unit, 
            amount_ex : received.amount, 
            del_ex : received.expected_delivery, 
            buyer_ex : received.eid_buyer, 
            pdel_ex : received.promise_delivery, 
            seller_ex : received.eid_seller, 
            prev_ex : received.prev_transactions
        }
        console.log(transaction_details)
        var transaction_string = JSON.stringify(transaction_details);
        console.log(transaction_string)
        return transaction_string
    }
    catch {
        console.log("Exception occured while get Data to hash function was executing!!!");
    }
    
}
async function getDataToHashWithSignature(received) {
    try {
        var transaction_details = {
            key_ex : received.transactionID,
            pcode_ex : received.product_code,
            q_ex :received.quantity,
            price_ex : received.price,
            pname_ex :received.product_name,
            batch_ex : "100",
            unit_ex : received.quantity_unit, 
            amount_ex : received.amount, 
            del_ex : received.expected_delivery, 
            buyer_ex : received.eid_buyer, 
            pdel_ex : received.promise_delivery, 
            seller_ex : received.eid_seller, 
            prev_ex : received.prev_transactions,
            signature1 : received.signature1
        }
        console.log(transaction_details)
        var transaction_string = JSON.stringify(transaction_details);
        console.log(transaction_string)
        return transaction_string
    }
    catch {
        console.log("Exception occured while get Data to hash function was executing!!!");
    }
    
}
async function signDocument(hash, userid, org) {
    try {
        const { KJUR, KEYUTIL } = require('jsrsasign');
        const { Gateway, Wallets } = require('fabric-network');
        const fs = require('fs');
        const path = require('path');
        // load the network configuration
        var osname;
        if(os.type()=='Windows_NT')
            osname='windows';
        else
            osname='linux';

        const ccpPath = path.resolve(__dirname, '..','1st_prototype_'+osname, 'organizations', 'peerOrganizations', org+'.example.com', 'connection-'+org+'.json');
        let ccp = JSON.parse(fs.readFileSync(ccpPath, 'utf8'));

        // Create a new file system based wallet for managing identities.
        const walletPath = path.join(process.cwd(), 'wallet');
        const wallet = await Wallets.newFileSystemWallet(walletPath);
        console.log(`Wallet path: ${walletPath}`);

        // Check to see if we've already enrolled the user.
        const identity = await wallet.get(userid);
        if (!identity) {
            console.log('An identity for the user '+userid+' does not exist in the wallet');
            console.log('Run the registerUser.js application before retrying');
            return;
        }
        
        // extract certificate info from wallet
        const walletContents = await wallet.get(userid);
        const userPrivateKey = walletContents.credentials.privateKey;

        //Print public key for info
        const certLoaded = walletContents.credentials.certificate;
        console.log("Certloaded: "+certLoaded);
        var userPublicKey = KEYUTIL.getKey(certLoaded);
        console.log("The public key is: " + userPublicKey);
        var sig = new KJUR.crypto.Signature({"alg": "SHA256withECDSA"});
        sig.init(userPrivateKey, "");
        sig.updateHex(hash);
        var sigValueHex = sig.sign();
        var sigValueBase64 = new Buffer.from(sigValueHex, 'hex').toString('base64');
        console.log(sigValueBase64)
        signature_string = await sigValueBase64.toString('base64');
        console.log("Signature: " + signature_string);
                
        //---------------To-do--------------------//
        const fs1 = require('fs') 

        // Data which will write in a file. 
        let data = "Signature: "+signature_string+"\n "+"Certificate: "+certLoaded;
        
        // Write data in 'Output.txt' . 
        fs1.writeFile('Output.txt', data, (err) => { 
            
            // In case of a error throw err. 
            if (err) throw err; 
        }) 
        console.log("Written!!!!!")
        //----------------------------------//

        // Create a new gateway for connecting to our peer node.
        const gateway = new Gateway();
        await gateway.connect(ccp, { wallet, identity: userid, discovery: { enabled: true, asLocalhost: true } });

        console.log('Signature has been created');
        //return true;
        // Disconnect from the gateway.
        await gateway.disconnect();
        return await signature_string;

    } catch (error) {
        console.error(`Failed to generate Signature: ${error}`);
        //return false;
        process.exit(1);
    }
    
}
async function generate(received) {
    try {
        var transaction_string = await getDataToHash(received)
        var hashToAction =  await calculateHash(transaction_string)
        console.log("Hash of the file: " + hashToAction);

        //Sign the document
        var signature_string = signDocument(hashToAction, received.userid, received.org)
        return await signature_string;

    } catch (error) {
        console.error(`Failed to generate Signature: ${error}`);
        //return false;
        process.exit(1);
    }
}

//main();
module.exports={generate, getDataToHash, calculateHash, getDataToHashWithSignature, signDocument};