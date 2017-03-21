# TODO: not updated since rename from level_instance, or since we redid how all models are done; probably busted

mongoose = require 'mongoose'
plugins = require '../plugins/plugins'
jsonschema = require '../../app/schemas/models/level_feedback'
config = require '../../server_config'

LevelFeedbackSchema = new mongoose.Schema({
  created:
    type: Date
    'default': Date.now
}, {strict: false,read:config.mongo.readpref})

LevelFeedbackSchema.index({created: 1})
LevelFeedbackSchema.index({creator: 1})

module.exports = LevelFeedback = mongoose.model('level.feedback', LevelFeedbackSchema)
