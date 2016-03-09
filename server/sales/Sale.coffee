mongoose = require('mongoose')
config = require '../../server_config'
SaleSchema = new mongoose.Schema({status: String}, {strict: false,read:config.mongo.readpref})
SaleSchema.index({recipient: 1, 'sold.original': 1}, {unique: true, name: 'unique sale'})

module.exports = mongoose.model('sale', SaleSchema)
