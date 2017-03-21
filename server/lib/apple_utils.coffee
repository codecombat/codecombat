config = require '../../server_config'

module.exports.verifyReceipt = (receipt, done) ->
  formFields = { 'receipt-data': receipt }
  request.post {url: config.apple.verifyURL, json: formFields}, (err, res, body) ->
    done(err, body)
