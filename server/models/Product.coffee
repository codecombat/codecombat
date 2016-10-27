mongoose = require('mongoose')
config = require '../../server_config'
ProductSchema = new mongoose.Schema({}, {strict: false,read:config.mongo.readpref})

module.exports = mongoose.model('product', ProductSchema)
