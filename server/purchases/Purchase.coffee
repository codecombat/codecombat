mongoose = require('mongoose')

PurchaseSchema = new mongoose.Schema({status: String}, {strict: false,read:'nearest'})
PurchaseSchema.index({recipient: 1, 'purchased.original': 1}, {unique: true, name: 'unique purchase'})

module.exports = mongoose.model('purchase', PurchaseSchema)
