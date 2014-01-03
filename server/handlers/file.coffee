File = require('../models/File')
Handler = require('./Handler')

FileHandler = class FileHandler extends Handler
  modelClass: File
  editableProperties: ['metadata']

  hasAccess: (req) ->
    req.method is 'GET'

# TODO: once we're building the clients, need special GET handler, search handler

module.exports = new FileHandler()
