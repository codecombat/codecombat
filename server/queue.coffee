config = require '../server_config'
winston = require 'winston'
mongoose = require 'mongoose'
async = require 'async'
errors = require './errors'

testing = '--unittest' in process.argv

module.exports.connect = ->
  return


module.exports.connectToRemoteQueue = ->
  return

module.exports.connectToLocalQueue = ->
  return