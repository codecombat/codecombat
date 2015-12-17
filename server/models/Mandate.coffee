mongoose = require('mongoose')
config = require '../../server_config'
MandateSchema = new mongoose.Schema {}, {strict: false, read: config.mongo.readpref}

module.exports = mongoose.model('mandate', MandateSchema)
