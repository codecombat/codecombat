mongoose = require('mongoose')
config = require '../../server_config'
PurchaseSchema = new mongoose.Schema({status: String}, {strict: false,read:config.mongo.readpref})
PurchaseSchema.index({recipient: 1, 'purchased.original': 1}, {unique: true, name: 'unique purchase'})

module.exports = mongoose.model('purchase', PurchaseSchema)
