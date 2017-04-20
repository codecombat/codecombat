utils = require '../lib/utils'
errors = require '../commons/errors'
wrap = require 'co-express'
database = require '../commons/database'
parse = require '../commons/parse'

module.exports =
  deleteTranslationCoverage: (Model) -> wrap (req, res) ->
    doc = yield database.getDocFromHandle(req, Model)
    if not doc
      throw new errors.NotFound('Document not found.')
    yield doc.update({ $unset: { i18nCoverage: '' }})
    docObj = _.without(doc.toObject({ req }), 'i18nCoverage')
    res.send(docObj)
