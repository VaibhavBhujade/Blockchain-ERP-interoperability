var net = require('net');
const invoketx=require('./invoketx.js')
const querytx=require('./querytx.js')
const enrollAdmin=require('./enrollAdmin.js')
const registerUser=require('./registerUser.js')
const generateSign=require('./generateSign.js')
const traceability = require('./traceability.js')

// A use-once date server. Clients get the date on connection and that's it!
var server = net.createServer((socket) => {
    console.log("Waiting for connection");
    socket.on('data', (buffer) => {
        console.log('Request from', socket.remoteAddress, 'port', socket.remotePort);
        var received=JSON.parse(buffer.toString('utf-8'));
        console.log(`${received.label}\n`);

        
        if(received.label=='transaction')
        {
            invoketx.main(received);
            var msgx = "transaction done";
            socket.write(msgx);
            socket.end();
        }
        else if(received.label=='query')
        {
            querytx.query_all(received);
            (async () => {
               const k = await querytx.query_all(received)
               console.log(k);
               console.log(typeof k);
               socket.write(k);
               socket.end();
              })()  
        }
        else if(received.label=='generate')
        {
            //generateSign.generate(received);
            (async () => {
               const k = await generateSign.generate(received)
               console.log(k);
               console.log(typeof k);
               socket.write(k);
               socket.end();
              })()  
        }
        else if(received.label=='enroll')
        {
            enrollAdmin._enrollAdmin(received);
            var msgx = "enroll done";
            socket.write(msgx);
            console.log("Enroll request");
            socket.end();
        }
        else if(received.label=='register')
        {
            registerUser._registerUser(received);
            var msgx = "register done";
            socket.write(msgx);
            socket.end();
        }
        else if(received.label=='trace')
        {
            // traceability.trace(received);
            (async () => {
               const k = await traceability.trace(received);
               console.log(k);
               console.log(typeof k);
               socket.write(k);
               socket.end();
              })() 
            console.log("Traced!!");
            
        }
        else
        console.log("Invalid request");

    });
});

server.listen(10000);
