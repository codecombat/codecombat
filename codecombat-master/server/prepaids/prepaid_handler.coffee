Handler = require '../commons/Handler'
Prepaid = require './Prepaid'

# TODO: Should this happen on a save() call instead of a prepaid/-/create post?
# TODO: Probably a better way to create a unique 8 charactor string property using db voodoo

PrepaidHandler = class PrepaidHandler extends Handler
  modelClass: Prepaid
  jsonSchema: require '../../app/schemas/models/prepaid.schema'
  allowedMethods: ['POST']

  hasAccess: (req) ->
    req.user?.isAdmin()

  getByRelationship: (req, res, args...) ->
    relationship = args[1]
    return @createPrepaid(req, res) if relationship is 'create'
    super arguments...

  createPrepaid: (req, res) ->
    return @sendForbiddenError(res) unless @hasAccess(req)
    return @sendForbiddenError(res) unless req.body.type is 'subscription'
    @generateNewCode (code) =>
      return @sendDatabaseError(res, 'Database error.') unless code
      prepaid = new Prepaid
        creator: req.user.id
        type: req.body.type
        status: 'active'
        code: code
        properties:
          couponID: 'free'
      prepaid.save (err) =>
        return @sendDatabaseError(res, err) if err
        @sendSuccess(res, prepaid.toObject())

  generateNewCode: (done) ->
    tryCode = ->
      code = _.sample("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789", 8).join('')
      Prepaid.findOne code: code, (err, prepaid) ->
        return if err
        return done(code) unless prepaid
        tryCode()
    tryCode()

module.exports = new PrepaidHandler()
