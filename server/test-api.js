// ローカルAPI呼び出しテスト用スクリプト
const http = require('http');

const testData = JSON.stringify({
  task: '部屋の掃除をする'
});

const options = {
  hostname: '127.0.0.1',
  port: 5001,
  path: '/stepbystep-tasks/us-central1/splitTask',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(testData)
  }
};

console.log('Testing splitTask API...');

const req = http.request(options, (res) => {
  console.log(`Status: ${res.statusCode}`);
  console.log(`Headers: ${JSON.stringify(res.headers)}`);
  
  let data = '';
  res.on('data', (chunk) => {
    data += chunk;
  });
  
  res.on('end', () => {
    console.log('Response:');
    console.log(JSON.stringify(JSON.parse(data), null, 2));
  });
});

req.on('error', (e) => {
  console.error(`Request error: ${e.message}`);
});

req.write(testData);
req.end();