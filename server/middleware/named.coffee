utils = require '../lib/utils'
errors = require '../commons/errors'
wrap = require 'co-express'
Promise = require 'bluebird'
database = require '../commons/database'
mongoose = require 'mongoose'

module.exports =
  names: (Model, options={}) -> wrap (req, res) ->
    # TODO: migrate to /db/collection?ids=...&project=... and /db/collection?originals=...&project=...

    ids = req.query.ids or req.body.ids
    ids = ids.split(',') if _.isString ids
    ids = _.uniq ids

    # Hack: levels loading thang types need the components returned as well.
    # Need a way to specify a projection for a query.
    project = {name: 1, original: 1, kind: 1, components: 1, prerenderedSpriteSheetData: 1}
    sort = if Model.schema.uses_coco_versions then {'version.major': -1, 'version.minor': -1} else {}

    for id in ids
      if not database.isID(id)
        throw new errors.UnprocessableEntity('Invalid MongoDB id given')
        
    ids = (mongoose.Types.ObjectId(id) for id in ids)

    promises = []
    for id in ids
      q = if Model.schema.uses_coco_versions then { original: id } else { _id: id }
      promises.push Model.findOne(q).select(project).sort(sort).exec()

    documents = yield promises
    res.status(200).send(documents)
