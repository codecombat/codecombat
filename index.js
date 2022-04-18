var majorVersion = parseInt(process.versions.node.split('.')[0]);
if (majorVersion < 10) {
  console.error('This requires Node v14. Your version:', process.version);
  process.exit(1);
}
if (majorVersion < 14) {
  console.warn('WARNING: This requires Node v14; please upgrade. Your version:', process.versions.node);
}
require('coffee-script');
require('coffee-script/register');
const product = process.env.COCO_PRODUCT || 'codecombat'
const productSuffix = { codecombat: 'coco', ozaria: 'ozar' }[product]
require.extensions[`.${productSuffix}.coffee`] = require.extensions['.coffee']
var server = require('./server');
server.startServer();
