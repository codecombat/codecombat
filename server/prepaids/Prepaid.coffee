mongoose = require 'mongoose'
config = require '../../server_config'
PrepaidSchema = new mongoose.Schema {}, {strict: false, minimize: false,read:config.mongo.readpref}

module.exports = Prepaid = mongoose.model('prepaid', PrepaidSchema)
