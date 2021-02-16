/*
 * Copyright IBM Corp. All Rights Reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

'use strict';
const Queue=require('./queue.js');
const { Gateway, Wallets } = require('fabric-network');
const path = require('path');
const fs = require('fs');
var os=require('os');
const querytx=require('./querytx.js')
var result_final;
async function getPrevIds(received, txid) {
    try {
        var osname;
        if(os.type()=='Windows_NT')
            osname='windows';
        else
            osname='linux';

        const ccpPath = path.resolve(__dirname, '..', '1st_prototype_'+osname, 'organizations', 'peerOrganizations', received.org+'.example.com', 'connection-'+received.org+'.json');
        const ccp = JSON.parse(fs.readFileSync(ccpPath, 'utf8'));

        // Create a new file system based wallet for managing identities.
        const walletPath = await path.join(process.cwd(), 'wallet');
        const wallet = await Wallets.newFileSystemWallet(walletPath);
        console.log(`Wallet path: ${walletPath}`);

        // Check to see if we've already enrolled the user.
        const identity = await wallet.get(received.userid);
        if (!identity) {
            console.log('An identity for the user '+" 'received.userid' "+' does not exist in the wallet');
            console.log('Run the registerUser.js application before retrying');
            return;
        }

        // Create a new gateway for connecting to our peer node.
        const gateway = new Gateway();
        await gateway.connect(ccp, { wallet, identity: received.userid, discovery: { enabled: true, asLocalhost: true } });

        // Get the network (channel) our contract is deployed to.
        const network = await gateway.getNetwork('demochannel');

        // Get the contract from the network.
        const contract = network.getContract('transactionv1');
        // get transacrtion
        var query_result = await contract.evaluateTransaction('Query_One',txid);
        var temp = JSON.parse(query_result.toString());
        //Get prevtxid from json trasaction
        var prev_list = temp.prev_txid;
        //Split the prevtxid and store in a list
        var final_list = prev_list.split(',');
        return await final_list;
    }
    catch (error) {
        console.error(`Failed to evaluate transaction: ${error}`);
        process.exit(1);
    }
}


async function trace(received) {
    try {
        // load the network configuration
        var osname;
        if(os.type()=='Windows_NT')
            osname='windows';
        else
            osname='linux';

        const ccpPath = path.resolve(__dirname, '..', '1st_prototype_'+osname, 'organizations', 'peerOrganizations', received.org+'.example.com', 'connection-'+received.org+'.json');
        const ccp = JSON.parse(fs.readFileSync(ccpPath, 'utf8'));

        // Create a new file system based wallet for managing identities.
        const walletPath = await path.join(process.cwd(), 'wallet');
        const wallet = await Wallets.newFileSystemWallet(walletPath);
        console.log(`Wallet path: ${walletPath}`);

        // Check to see if we've already enrolled the user.
        const identity = await wallet.get(received.userid);
        if (!identity) {
            console.log('An identity for the user '+" 'received.userid' "+' does not exist in the wallet');
            console.log('Run the registerUser.js application before retrying');
            return;
        }

        // Create a new gateway for connecting to our peer node.
        const gateway = new Gateway();
        await gateway.connect(ccp, { wallet, identity: received.userid, discovery: { enabled: true, asLocalhost: true } });

        // Get the network (channel) our contract is deployed to.
        const network = await gateway.getNetwork('demochannel');

        // Get the contract from the network.
        const contract = network.getContract('transactionv1');

        console.log(received);
    
        //Find prev ids list
        console.log(await getPrevIds(received,received.tx_id));
       
        let queue = new Queue();
        queue.enqueue(received.tx_id); 
        console.log(queue.isEmpty()); 
        var result=[];
        while(!queue.isEmpty())
        {
            console.log(queue.front());

            var txid = queue.front();
            const trace_query = await contract.evaluateTransaction('Query_One',txid);

            result.push(trace_query.toString());
            queue.dequeue();
            var next_ids = await getPrevIds(received,txid);
            for(var i=0; i<next_ids.length; i++)
            {
                if(next_ids[i]!='null') 
                    queue.enqueue(next_ids[i]);
            }

        }



        result_final = "";
        await gateway.disconnect();
       
        return await result.toString();
        
    } catch (error) {
        console.error(`Failed to evaluate transaction: ${error}`);
        process.exit(1);
    }
}



//if you want to print here uncomment below lines.
// (async () => {
//     console.log(await query_all())
//   })()
module.exports={trace};
