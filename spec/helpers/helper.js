var _ = require('lodash');

require('coffee-script');
require('coffee-script/register');

var oldIt = global.it;
global.it = function(description, testFn) {
  if(testFn.constructor.name === 'GeneratorFunction'){
    throw(Error("You didn't wrap a generator function! Do it like this: it 'does a thing', utils.wrap (done) ->"))
  }
  oldIt.apply(jasmine.getEnv(), arguments)
}

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

jasmine.DEFAULT_TIMEOUT_INTERVAL = 1000 * 15; // for long Stripe tests
require('../server/common'); // Make sure global testing functions are set up

// Ignore Stripe/Nocking erroring
console.error = function() {
  try {
    if(arguments[1].type === 'StripeInvalidRequest')
      return;
    if(arguments[1].stack.indexOf('An error occurred with our connection to Stripe') > -1)
      return;
  }
  catch (e) { }
  console.log.apply(console, arguments);
};

if (process.argv.indexOf('--with-test-names') > -1) {
  jasmine.getEnv().addReporter({
    specStarted: function(result){
      // Printing weirdly so pass/fail indicator is on the same line as the test name
      process.stdout.write('\n' + result.fullName);
    }
  })
}

// TODO: Share this between client and server tests
customMatchers = {
  toDeepEqual: function (util, customEqualityTesters) {
    return {
      compare: function (actual, expected) {
        pass = _.isEqual(actual, expected)
        message = `Expected ${JSON.stringify(actual, null, '\t')} to DEEP EQUAL ${JSON.stringify(expected, null, '\t')}`
        return {pass, message}
      }
    }
  }
}

var initialized = false;
beforeEach(function(done) {
  jasmine.addMatchers(customMatchers);
  if (initialized) {
    return done();
  }
  console.log('/spec/helpers/helper.js - Initializing spec environment...');
  var User = require('../../server/models/User');

  var async = require('async');
  async.series([
    function(cb) {
      // Start the server
      var server = require('../../server');
      server.startServer(cb);
    },
    function(cb) {
      // 5. Check actual database
      User.find({}).count(function(err, count) {
        // For this to serve as a line of defense against testing with the
        // production DB, tests must be run with
        expect(err).toBeNull();
        expect(count).toBeLessThan(100);
        if(err || count >= 100) {
          // the only way to be sure we don't keep going with the tests
          process.exit(1);
        }
        cb()
      });
    },
    function(cb) {
      // Clear db
      var mongoose = require('mongoose');
      mongoose.connection.db.command({dropDatabase:1}, function(err, result) {
        if (err) { console.log(err); }
        cb(err);
      });
    },
    function(cb) {
      // Make sure User schemas are created
      // TODO: Ensure all models are fully indexed before starting tests
      User.on('index', cb)
    },
    function(cb) {
      // Initially added to init products... but don't need that anymore. Shouldn't need this, either,
      // but all the tests break if I remove it. TODO: Remove this without breaking tests.
      var utils = require('../server/utils');
      request = require('../server/request');
      utils.initUser()
        .then(function (user) {
          return utils.loginUser(user, {request: request})
        })
        .then(function () {
          cb()
        });
    }
  ],
  function(err) {
    if (err) {
      process.exit(1);
    }
    initialized = true;
    console.log('/spec/helpers/helper.js - Done');
    done();
  });
});
