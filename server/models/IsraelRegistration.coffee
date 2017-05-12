mongoose = require 'mongoose'
config = require '../../server_config'
jsonSchema = {type: 'object', additionalProperties: 'true'}

IsraelRegistrationSchema = new mongoose.Schema {}, {strict: false, minimize: false, read: config.mongo.readpref}
IsraelRegistrationSchema.statics.jsonSchema = jsonSchema

IsraelRegistrationSchema.index({'user.userid': 1}, {name: 'user.userid index', unique: true})

module.exports = IsraelRegistration = mongoose.model 'IsraelRegistration', IsraelRegistrationSchema, 'israel.registrations'
