./organizations/ccp-generate-new.sh
echo "connection profiles created"

chmod a+rwx chaincode
echo "unlocked chaincode"

cp -R /home/aakanksha/transactionv1* /home/aakanksha/Documents/fabric-samples-master/1st_prototype_linux/chaincode
echo "copied to chaincode"
chmod a+rwx chaincode/transactionv1