basicAuth = require('basic-auth')
APIClient = require '../models/APIClient'
User = require '../models/User'
wrap = require 'co-express'
errors = require '../commons/errors'
database = require '../commons/database'
config = require '../../server_config'
Prepaid = require '../models/Prepaid'
moment = require 'moment'
oauth = require '../lib/oauth'

INCLUDED_USER_PRIVATE_PROPS = ['email', 'oAuthIdentities']
DATETIME_REGEX = /^\d{4}-\d{2}-\d{2}T\d{2}\:\d{2}\:\d{2}\.\d{3}Z$/ # JavaScript Date's toISOString() output

clientAuth = wrap (req, res, next) ->
  if config.isProduction and not req.isSecure()
    throw new errors.Unauthorized('API calls must be over HTTPS.')

  creds = basicAuth(req)

  unless creds and creds.name and creds.pass
    throw new errors.Unauthorized('Basic auth credentials not provided.')
    
  client = yield APIClient.findById(creds.name)
  if not client
    throw new errors.Unauthorized('Credentials incorrect.')
    
  hashed = APIClient.hash(creds.pass)
  if client.get('secret') isnt hashed
    throw new errors.Unauthorized('Credentials incorrect.')

  req.client = client
  next()

  
postUser = wrap (req, res) ->
  user = new User({anonymous: false})
  user.set(_.pick(req.body, 'name', 'email'))
  user.set('clientCreator', req.client._id)
  database.validateDoc(user)
  user = yield user.save()
  res.status(201).send(user.toObject({req, includedPrivates: INCLUDED_USER_PRIVATE_PROPS, virtuals: true}))
  
  
getUser = wrap (req, res) ->
  user = yield database.getDocFromHandle(req, User)
  if not user
    throw new errors.NotFound('User not found.')

  exception = req.client.id is '582a134eb9bce324006210e7' and user.get('israelId')
  unless exception or req.client._id.equals(user.get('clientCreator'))
    throw new errors.Forbidden('Must have created the user.')

  res.send(user.toObject({req, includedPrivates: INCLUDED_USER_PRIVATE_PROPS, virtuals: true}))


getUserLookupByIsraelId = wrap (req, res) ->
  { israelId } = req.params
  user = yield User.findOne({ israelId })
  if not user
    throw new errors.NotFound('User not found.')
    
  res.redirect(301, "/api/users/#{user.id}")
  
  
postUserOAuthIdentity = wrap (req, res) ->
  user = yield database.getDocFromHandle(req, User)
  if not user
    throw new errors.NotFound('User not found.')
    
  unless req.client._id.equals(user.get('clientCreator'))
    throw new errors.Forbidden('Must have created the user to perform this action.')
    
  { provider: providerId, accessToken, code } = req.body or {}
  identity = yield oauth.getIdentityFromOAuth({providerId, accessToken, code})
  
  otherUser = yield User.findOne({oAuthIdentities: { $elemMatch: identity }})
  if otherUser
    throw new errors.Conflict('User already exists with this identity')

  yield user.update({$push: {oAuthIdentities: identity}})
  oAuthIdentities = user.get('oAuthIdentities') or []
  oAuthIdentities.push(identity)
  user.set({oAuthIdentities})
  res.send(user.toObject({req, includedPrivates: INCLUDED_USER_PRIVATE_PROPS, virtuals: true}))
  
  
putUserSubscription = wrap (req, res) ->
  user = yield database.getDocFromHandle(req, User)
  if not user
    throw new errors.NotFound('User not found.')

  unless req.client._id.equals(user.get('clientCreator'))
    throw new errors.Forbidden('Must have created the user to perform this action.')
    
  # TODO: Remove 'endDate' parameter
  { endDate, ends } = req.body
  ends ?= endDate
  unless ends and DATETIME_REGEX.test(ends)
    throw new errors.UnprocessableEntity('ends is not a properly formatted.')
    
  { free } = user.get('stripe') ? {}
  if free is true
    throw new errors.UnprocessableEntity('This user already has free premium access')

  # if the user is already subscribed, this prepaid starts when it would have ended, otherwise it starts now 
  now = new Date().toISOString()
  startDate = if _.isString(free) then moment(free).toISOString() else now
  startDate = now if startDate < now
  
  if startDate >= ends
    throw new errors.UnprocessableEntity("ends is before when the subscription would start: #{startDate}")
    
  prepaid = new Prepaid({
    clientCreator: req.client._id
    redeemers: []
    maxRedeemers: 1
    type: 'terminal_subscription'
    startDate
    endDate: ends
  })
  yield prepaid.save()
  yield prepaid.redeem(user)
  res.send(user.toObject({req, includedPrivates: INCLUDED_USER_PRIVATE_PROPS, virtuals: true}))

  
putUserLicense = wrap (req, res) ->
  user = yield database.getDocFromHandle(req, User)
  if not user
    throw new errors.NotFound('User not found.')

  unless req.client._id.equals(user.get('clientCreator'))
    throw new errors.Forbidden('Must have created the user to perform this action.')

  { ends } = req.body
  unless ends and DATETIME_REGEX.test(ends)
    throw new errors.UnprocessableEntity('ends is not a properly formatted.')

  now = new Date().toISOString()
  if ends < now
    throw new errors.UnprocessableEntity('ends must be in the future.')

  # if the user is already subscribed, this prepaid starts when it would have ended, otherwise it starts now 
  { endDate } = user.get('coursePrepaid') ? {}
  if endDate and endDate >= now
    throw new errors.UnprocessableEntity("User is already enrolled, and may not be enrolled again until their current enrollment is finished")

  prepaid = new Prepaid({
    clientCreator: req.client._id
    redeemers: []
    maxRedeemers: 1
    type: 'course'
    startDate: now
    endDate: ends
  })
  yield prepaid.save()
  yield prepaid.redeem(user)
  res.send(user.toObject({req, includedPrivates: INCLUDED_USER_PRIVATE_PROPS, virtuals: true}))

  
module.exports = {
  clientAuth
  getUser
  getUserLookupByIsraelId
  postUser
  postUserOAuthIdentity
  putUserSubscription
  putUserLicense
}
