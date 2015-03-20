mongoose = require 'mongoose'

PrepaidSchema = new mongoose.Schema {}, {strict: false, minimize: false,read:'nearest'}

module.exports = Prepaid = mongoose.model('prepaid', PrepaidSchema)
