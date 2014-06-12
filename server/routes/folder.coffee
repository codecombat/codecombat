mongoose = require('mongoose')
errors = require '../commons/errors'

module.exports.setup = (app) ->
  app.all '/folder*', (req, res) ->
    return folderGet(req, res) if req.route.method is 'get'
    return errors.badMethod(res, ['GET'])

folderGet = (req, res) ->
  folder = req.path[7..]
  userfolder = "/user-#{req.user.id}/"
  folder = userfolder if folder is '/me/'
  return errors.forbidden(res) unless (folder is userfolder) or (req.user.isAdmin())
    
  mongoose.connection.db.collection 'media.files', (errors, collection) ->
    collection.find({'metadata.path': folder}).toArray (err, results) ->
      res.send(results)
      res.end()
