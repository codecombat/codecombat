mongoose = require 'mongoose'
plugins = require '../plugins/plugins'
config = require '../../server_config'

UserCodeProblemSchema = new mongoose.Schema({
  created:
    type: Date
    'default': Date.now
}, {strict: false,read:config.mongo.readpref})

module.exports = UserCodeProblem = mongoose.model('user.code.problem', UserCodeProblemSchema)
