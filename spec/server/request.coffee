request = require('request').defaults({jar: true})
Promise = require 'bluebird'
Promise.promisifyAll(request, {multiArgs: true})
module.exports = request