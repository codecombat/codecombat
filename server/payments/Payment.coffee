mongoose = require('mongoose')

PaymentSchema = new mongoose.Schema({}, {strict: false, read:'nearest'})
PaymentSchema.index({recipient: 1, 'stripe.timestamp': 1, 'ios.transactionID'}, {unique: true, name: 'unique payment'})

module.exports = mongoose.model('payment', PaymentSchema)
