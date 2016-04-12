utils = require '../lib/utils'
errors = require '../commons/errors'
wrap = require 'co-express'
database = require '../commons/database'
parse = require '../commons/parse'

module.exports =
  get: (Model, options={}) -> wrap (req, res) ->
    dbq = Model.find()
    dbq.limit(parse.getLimitFromReq(req))
    dbq.skip(parse.getSkipFromReq(req))
    dbq.select(parse.getProjectFromReq(req))
    database.applyCustomSearchToDBQ(req, dbq)
  
    if Model.schema.uses_coco_translation_coverage and req.query.view is 'i18n-coverage'
      dbq.find({ slug: {$exists: true}, i18nCoverage: {$exists: true} })
  
    results = yield database.viewSearch(dbq, req)
    res.send(results)

  post: (Model, options={}) -> wrap (req, res) ->
    doc = database.initDoc(req, Model)
    database.assignBody(req, doc)
    database.validateDoc(doc)
    doc = yield doc.save()
    res.status(201).send(doc.toObject())
        
  getByHandle: (Model, options={}) -> wrap (req, res) ->
    doc = yield database.getDocFromHandle(req, Model)
    if not doc
      throw new errors.NotFound('Document not found.')
    res.status(200).send(doc.toObject())
          
  put: (Model, options={}) -> wrap (req, res) ->
    doc = yield database.getDocFromHandle(req, Model)
    if not doc
      throw new errors.NotFound('Document not found.')

    database.assignBody(req, doc)
    database.validateDoc(doc)
    doc = yield doc.save()
    res.status(200).send(doc.toObject())

  delete: (Model, options={}) -> wrap (req, res) ->
    doc = yield database.getDocFromHandle(req, Model)
    if not doc
      throw new errors.NotFound('Document not found.')
    yield doc.remove()
    res.status(204).end()