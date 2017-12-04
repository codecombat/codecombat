errors = require '../commons/errors'
log = require 'winston'
wrap = require 'co-express'
# database = require '../commons/database'
# mongoose = require 'mongoose'
User = require '../models/User'
# parse = require '../commons/parse'
discourse = require '../lib/discourse'

module.exports =
  webhooks:
    postUser: wrap (req, res, next) ->
      # console.log JSON.parse(req.body)
      console.log req.body
      console.log req.body.user
      console.log req.body.user?.email
      if not req.body.user?.email
        log.debug("Discourse webhook triggered, but no email provided. id:#{req.body.user?.id} name:#{req.body.user?.name}")
        throw new errors.UnprocessableEntity("Discourse webhook triggered, but no email provided. id:#{req.body.user?.id} name:#{req.body.user?.name}")
      cocoUser = yield User.findOne({ emailLower: req.body.user.email.toLowerCase() })
      console.log cocoUser.toObject()
      console.log cocoUser.get('email')
      
      # TODO: Finalize whether to filter by emailVerified
      if not cocoUser.get('emailVerified')
        log.debug("Discourse webhook triggered, but user's email is not yet verified")
      
      if cocoUser.get('discourse')?.verified_teacher
        console.log "Adding user to verified_teachers on discourse based on CoCo flag"
        yield discourse.group('verified_teachers').addUsers(req.body.user.username)
          
        # for group in (cocoUser.get('discourse').groups or [])
        #   yield discourse.group('verified_teachers').addUsers(cocoUser.get('discourse')?.username)
      if not cocoUser.get('discourse')?.id
        console.log "Attaching discourse info to coco user"
        cocoUser.set({
          discourse: _.merge({}, cocoUser.get('discourse'), {
            username: req.body.user.username
            id: req.body.user.id
            verified_teacher: cocoUser.get('discourse')?.verified_teacher or false
            # groups: [].concat(cocoUser.get('discourse')?.groups or [])
          })
        })
        yield cocoUser.save()
        cocoUser = yield User.findOne({ emailLower: req.body.user.email.toLowerCase() })
      # console.log req.body
      res.status(200).send()
