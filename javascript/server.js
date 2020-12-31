const net = require('net');
const invoketx=require('./invoketx.js')
const querytx=require('./querytx.js')
const enrollAdmin=require('./enrollAdmin.js')
const registerUser=require('./registerUser.js')
// A use-once date server. Clients get the date on connection and that's it!
const server = net.createServer((socket) => {
    console.log("Waiting for connection");
    var response;
    socket.on('data', (buffer) => {
        console.log('Request from', socket.remoteAddress, 'port', socket.remotePort);
        var received=JSON.parse(buffer.toString('utf-8'));
        console.log(`${received.label}\n`);
        
        if(received.label=='transaction')
        {
            invoketx.main(received);
        }
        else if(received.label=='query')
        {
            console.log(received.enrollmentID)
        }
        else if(received.label=='enroll')
        {
            enrollAdmin._enrollAdmin(received);
            console.log("Enroll request");
        }
        else if(received.label=='register')
        {
            registerUser._registerUser(received);
        }
        else
        console.log("Invalid request");

    });
 
    socket.end();
});

server.listen(10000);