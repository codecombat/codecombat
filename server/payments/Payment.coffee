mongoose = require('mongoose')

PaymentSchema = new mongoose.Schema({}, {strict:false, minimize: false})
PaymentSchema.index({recipient: 1, 'stripe.timestamp': 1, 'ios.transactionID'}, {unique: true, name: 'unique payment'})

module.exports = mongoose.model('payment', PaymentSchema)
