config = require '../../server_config'
Promise = require 'bluebird'

paypal = require('paypal-rest-sdk')
paypal.configure({
  'mode': if config.isProduction then 'live' else 'sandbox'
  'client_id': config.paypal.clientID
  'client_secret': config.paypal.clientSecret
})

Promise.promisifyAll(paypal.billingAgreement)
Promise.promisifyAll(paypal.payment)

module.exports = paypal
