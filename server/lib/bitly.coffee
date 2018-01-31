config = require '../../server_config'
BitlyClient = require('bitly')
module.exports = BitlyClient(config.bitly.accessToken or '2ef4a986313451e8c44eeece891b80ed70af3398')  # TODO
