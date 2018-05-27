config = require '../../server_config'
BitlyClient = require('bitly')
module.exports = BitlyClient(config.bitly.accessToken)
