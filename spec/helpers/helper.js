var _ = require('lodash');

require('coffee-script');
require('coffee-script/register');

// Various assurances that in running tests, we don't accidentally run them
// on the production DB.

// 1. Make sure there are no environmental variables for COCO_ in place

var allowedKeys = [
  'COCO_TRAVIS_TEST'
];

var cocoKeysPresent = _.any(_.keys(process.env), function(envKey) {
  return envKey.indexOf('COCO_') >= 0 && !_.contains(allowedKeys, envKey);
});
if (cocoKeysPresent) {
  throw Error('Stopping server tests because COCO_ environmental variables are present.');
}

// 2. Clear environmental variables anyway
process.env = {};

// 3. Check server_config
global.testing = true;
var config = require('../../server_config');
if(config.mongo.host !== 'localhost') {
  throw Error('Stopping server tests because mongo host is not localhost.');
}

// 4. Check database string
var database = require('../../server/commons/database');
var dbString = 'mongodb://localhost:27017/coco_unittest';
if (database.generateMongoConnectionString() !== dbString) {
  throw Error('Stopping server tests because db connection string was not as expected.');
}

jasmine.DEFAULT_TIMEOUT_INTERVAL = 1000 * 120; // for long Stripe tests

describe('Server Test Helper', function() {
  it('starts the test server', function(done) {
    var server = require('../../server');
    server.startServer(done);
  });
  
  it('checks the db is fairly empty', function(done) {
    // 5. Check actual database.
    var User = require('../../server/users/User');
    User.find({}).count(function(err, count) {
      // For this to serve as a line of defense against testing with the
      // production DB, tests must be run with 
      expect(err).toBeNull();
      expect(count).toBeLessThan(100);
      if(err || count >= 100) {
        // the only way to be sure we don't keep going with the tests
        process.exit(1);
      }
      GLOBAL.mc.lists.subscribe = _.noop;
      done()
    });
  });
  
  it('clears the db', function(done) {
    var mongoose = require('mongoose');
    mongoose.connection.db.command({dropDatabase:1}, function(err, result) {
      if (err) { console.log(err); }
      done(); 
    });
  });
    
  it('initializes products', function(done) {
    var request = require('request');
    request.get(getURL('/db/products'), function(err, res, body) {
      expect(err).toBe(null);
      expect(res.statusCode).toBe(200);
      done();
    });
  })
});