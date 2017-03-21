utils = require '../lib/utils'
errors = require '../commons/errors'
wrap = require 'co-express'
Grid = require 'gridfs-stream'
Promise = require 'bluebird'
database = require '../commons/database'

module.exports =
  files: (Model, options={}) -> wrap (req, res) ->
    doc = yield database.getDocFromHandle(req, Model)
    if not doc
      throw new errors.NotFound('Document not found.')
    module = options.module or req.path[4..].split('/')[0]
    query = { 'metadata.path': "db/#{module}/#{doc.id}" }
    
    c = Grid.gfs.collection('media')
    c.findAsync = Promise.promisify(c.find)
    cursor = yield c.findAsync(query)
    cursor.toArrayAsync = Promise.promisify(cursor.toArray)
    files = yield cursor.toArrayAsync()
    res.status(200).send(files)