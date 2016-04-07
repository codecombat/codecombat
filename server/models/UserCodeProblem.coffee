mongoose = require 'mongoose'
plugins = require '../plugins/plugins'
config = require '../../server_config'

UserCodeProblemSchema = new mongoose.Schema({
  created:
    type: Date
    'default': Date.now
}, {strict: false,read:config.mongo.readpref})

UserCodeProblemSchema.index {levelID: 1, _id: 1}, {name: 'user code problems by level and date index'}

module.exports = UserCodeProblem = mongoose.model('user.code.problem', UserCodeProblemSchema)
