mongoose = require 'mongoose'
config = require '../../server_config'
jsonSchema = {type: 'object', additionalProperties: 'true'}

IsraelSolutionSchema = new mongoose.Schema {}, {strict: false, minimize: false, read: config.mongo.readpref}
IsraelSolutionSchema.statics.jsonSchema = jsonSchema

IsraelSolutionSchema.index({'solution.id': 1}, {name: 'solution.id index', unique: true})

module.exports = IsraelSolution = mongoose.model 'IsraelSolution', IsraelSolutionSchema, 'israel.solutions'
