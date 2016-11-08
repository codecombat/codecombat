errors = require '../commons/errors'
wrap = require 'co-express'
database = require '../commons/database'
Branch = require '../models/Branch'

post = wrap (req, res) ->
  branch = database.initDoc(req, Branch)
  database.assignBody(req, branch)
  updateBranch(branch, req.user)
  database.validateDoc(branch)
  branch = yield branch.save()
  res.status(201).send(branch.toObject({req}))
  
put = wrap (req, res) ->
  branch = yield database.getDocFromHandle(req, Branch)
  if not branch
    throw new errors.NotFound('Document not found.')
  database.assignBody(req, branch)
  updateBranch(branch, req.user)
  database.validateDoc(branch)
  branch = yield branch.save()
  res.status(200).send(branch.toObject())

updateBranch = (branch, user) ->
  branch.set('updated', new Date().toISOString())
  branch.set('updatedBy', user._id)
  branch.set('updatedByName', user.get('name'))
    
module.exports = {
  post
  put
}
