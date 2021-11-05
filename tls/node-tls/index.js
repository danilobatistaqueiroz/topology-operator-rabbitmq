const https = require('https');
const fs = require('fs');
const options = {
  key: fs.readFileSync('/home/element/labs/rabbitmq/kube-oper-rabbit/tls/node-tls/mkcert/localhost-key.pem'),
  cert: fs.readFileSync('/home/element/labs/rabbitmq/kube-oper-rabbit/tls/node-tls/mkcert/localhost-cert.pem'),
};
https
  .createServer(options, function (req, res) {
   if (req.url == '/') { //check the URL of the current request
        
        // set response header
        res.writeHead(200, { 'Content-Type': 'text/html' }); 
        
        // set response content    
        res.write('<html><body><p>This is home Page.</p></body></html>');
        res.end();
    
    }
    else if (req.url == "/student") {
        
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.write('<html><body><p>This is student Page.</p></body></html>');
        res.end();
    
    }
    else if (req.url == "/admin") {
        
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.write('<html><body><p>This is admin Page.</p></body></html>');
        res.end();
    
    }
    else
        res.end('Invalid Request!');
  })
  .listen(8080);
