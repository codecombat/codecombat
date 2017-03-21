var majorVersion = parseInt(process.versions.node.split('.')[0]);
if (majorVersion < 4) {
  console.error('Server requires Node v4 or higher. Your version:', process.version);
  process.exit(1);
}
if (majorVersion === 4) {
  console.warn('WARNING: You are using Node v4. Please upgrade to Node v5. Your version:', process.versions.node);
}
require('coffee-script');
require('coffee-script/register');
var server = require('./server');
server.startServer();
