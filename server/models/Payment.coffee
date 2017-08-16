mongoose = require('mongoose')
config = require '../../server_config'

PaymentSchema = new mongoose.Schema({}, {strict: false, read:config.mongo.readpref})
PaymentSchema.index({recipient: 1, 'stripe.timestamp': 1, 'ios.transactionID'}, {unique: true, name: 'unique payment'})
PaymentSchema.index({'payPal.id': 1}, {unique: true, name: 'unique PayPal payment'})
PaymentSchema.index({'payPalSale.id': 1}, {unique: true, name: 'unique PayPal sale payment'})

module.exports = mongoose.model('payment', PaymentSchema)
