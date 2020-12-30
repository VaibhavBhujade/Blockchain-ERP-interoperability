const net = require('net');
const invoketx=require('./invoketx.js')
const querytx=require('./querytx.js')
// A use-once date server. Clients get the date on connection and that's it!
const server = net.createServer((socket) => {
    console.log("Waiting for connection");
    
    socket.on('data', (buffer) => {
        console.log('Request from', socket.remoteAddress, 'port', socket.remotePort);
        var received=JSON.parse(buffer.toString('utf-8'));
        console.log(`${received.label}\n`);

        if(received.label=='transaction')
        {
            invoketx.main(received);
        }
        else
        console.log("Invalid request");
    });
    
    
    socket.end();
});

server.listen(10000);