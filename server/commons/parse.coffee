errors = require '../commons/errors'
_ = require 'lodash'
Promise = require 'bluebird'

module.exports =

  getLimitFromReq: (req, options) ->
    options = _.extend({
      max: 1000
      default: 100
      param: 'limit'
      min: 1
    }, options)

    limit = options.default

    if req.query[options.param]
      limit = parseInt(req.query[options.param])
      valid = tv4.validate(limit, {
        type: 'integer'
        maximum: options.max
        minimum: options.min
      })
      if not valid
        throw new errors.UnprocessableEntity("Invalid #{options.param} parameter.")

    return limit


  getSkipFromReq: (req, options) ->
    options = _.extend({
      max: 1000000
      default: 0
      param: 'skip'
    }, options)

    skip = options.default

    if req.query[options.param]
      skip = parseInt(req.query[options.param])
      valid = tv4.validate(skip, {
        type: 'integer'
        maximum: options.max
        minimum: 0
      })
      if not valid
        throw new errors.UnprocessableEntity("Invalid #{options.param} parameter.")

    return skip


  getProjectFromReq: (req, options) ->
    options = _.extend({}, options)
    return null unless req.query.project
    result = {}
    project = req.query.project
    if project is 'true'
      result = {original: 1, name: 1, version: 1, description: 1, slug: 1, kind: 1, created: 1, permissions: 1}
    else
      if _.isString(project)
        project = project.split(',')
      for field in project
        result[field] = 1

    return result
