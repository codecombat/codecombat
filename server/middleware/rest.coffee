utils = require '../lib/utils'
errors = require '../commons/errors'
wrap = require 'co-express'

module.exports =
  get: (Model, options={}) -> wrap (req, res) ->
    dbq = Model.find()
    dbq.limit(utils.getLimitFromReq(req))
    dbq.skip(utils.getSkipFromReq(req))
    dbq.select(utils.getProjectFromReq(req))
    utils.applyCustomSearchToDBQ(req, dbq)
  
    if Model.schema.uses_coco_translation_coverage and req.query.view is 'i18n-coverage'
      dbq.find({ slug: {$exists: true}, i18nCoverage: {$exists: true} })
  
    results = yield utils.viewSearchAsync(dbq, req)
    res.send(results)

  post: (Model, options={}) -> wrap (req, res) ->
    doc = utils.initDoc(req, Model)
    utils.assignBody(req, doc)
    utils.validateDoc(doc)
    doc = yield doc.save()
    res.status(201).send(doc.toObject())
        
  getByHandle: (Model, options={}) -> wrap (req, res) ->
    doc = yield utils.getDocFromHandleAsync(req, Model)
    if not doc
      throw new errors.NotFound('Document not found.')
    res.status(200).send(doc.toObject())
          
  put: (Model, options={}) -> wrap (req, res) ->
    doc = yield utils.getDocFromHandleAsync(req, Model)
    if not doc
      throw new errors.NotFound('Document not found.')
    
    utils.assignBody(req, doc)
    utils.validateDoc(doc)
    doc = yield doc.save()
    res.status(200).send(doc.toObject())
