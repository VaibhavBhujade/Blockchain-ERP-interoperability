'use strict';

const FabricCAServices = require('fabric-ca-client');
const { Wallets } = require('fabric-network');
const fs = require('fs');
const path = require('path');
var os=require('os');

async function _enrollAdmin(received) {
    try {
        var org = received.org;
        var orgName1 = org.charAt(0).toUpperCase() + org.substr(1);
        var orgMSP = orgName1 + 'MSP';
        // load the network configuration
        var osname;
        if(os.type()=='Windows_NT')
            osname='windows';
        else
            osname='linux';

        const ccpPath = path.resolve(__dirname, '..', '1st_prototype_'+osname, 'organizations', 'peerOrganizations', org+'.example.com', 'connection-'+org+'.json');
        const ccp = JSON.parse(fs.readFileSync(ccpPath, 'utf8'));
        
        

        // Create a new CA client for interacting with the CA.
        const caInfo = ccp.certificateAuthorities['ca.'+org+'.example.com'];
        const caTLSCACerts = caInfo.tlsCACerts.pem;
        const ca = new FabricCAServices(caInfo.url, { trustedRoots: caTLSCACerts, verify: false }, caInfo.caName);

        // Create a new file system based wallet for managing identities.
        const walletPath = path.join(process.cwd(), 'wallet');
        const wallet = await Wallets.newFileSystemWallet(walletPath);
        console.log(`Wallet path: ${walletPath}`);

        // Check to see if we've already enrolled the admin user.
        const identity = await wallet.get('ca-'+org+'-admin');
        if (identity) {
            console.log('An identity for the admin user "admin" already exists in the wallet');
            return;
        }

        // Enroll the admin user, and import the new identity into the wallet.
        //Enrollment ID:'ca-org-admin',Enrollment Secret: 'ca-org-adminpw'
        const enrollment = await ca.enroll({ enrollmentID: received.enrollmentID, enrollmentSecret: received.enrollmentSecret });
        const x509Identity = {
            credentials: {
                certificate: enrollment.certificate,
                privateKey: enrollment.key.toBytes(),
            },
            mspId: orgMSP,
            type: 'X.509',
        };
        await wallet.put('ca-'+org+'-admin', x509Identity);
        console.log('Successfully enrolled admin user "admin" and imported it into the wallet');

    } catch (error) {
        console.error(`Failed to enroll admin user "admin": ${error}`);
        process.exit(1);
    }
}

//main();
module.exports={_enrollAdmin};