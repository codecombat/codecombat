LevelComponent = require './LevelComponent'
Handler = require '../../commons/Handler'
mongoose = require 'mongoose'

LevelComponentHandler = class LevelComponentHandler extends Handler
  modelClass: LevelComponent
  jsonSchema: require '../../../app/schemas/models/level_component'
  editableProperties: [
    'system'
    'description'
    'code'
    'js'
    'codeLanguage'
    'dependencies'
    'propertyDocumentation'
    'configSchema'
    'name'
    'i18nCoverage'
  ]

  getEditableProperties: (req, document) ->
    props = super(req, document)
    props.push('official') if req.user?.isAdmin()
    props

  get: (req, res) ->
    if req.query.view is 'prop-doc-lookup'
      projection = {}
      if req.query.project
        projection[field] = 1 for field in req.query.project.split(',')

      query = slug: {$exists: true}

      try
        components = req.query.componentOriginals.split(',')
        components = (mongoose.Types.ObjectId(c) for c in components)
        properties = req.query.propertyNames.split(',')
      catch e
        return @sendBadInputError(res, 'Could not parse componentOriginals or propertyNames.')

      query['original'] = {$in: components}
      query.$or = [
        {'propertyDocumentation.name': {$in: properties}}
        {'propertyDocumentation.name': {$regex: /^cast.+/}}
      ]

      q = LevelComponent.find(query, projection)
      q.exec (err, documents) =>
        return @sendDatabaseError(res, err) if err
        documents = (@formatEntity(req, doc) for doc in documents)
        @sendSuccess(res, documents)
    else
      super(arguments...)

module.exports = new LevelComponentHandler()
