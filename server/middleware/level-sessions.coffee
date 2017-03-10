_ = require 'lodash'
errors = require '../commons/errors'
wrap = require 'co-express'
database = require '../commons/database'
LevelSession = require '../models/LevelSession'
moment = require 'moment'

getByHandle = wrap (req, res) ->
  session = yield database.getDocFromHandle(req, LevelSession)
  if not session
    throw new errors.NotFound('Level session not found.')
    
  unless _.any([
    session.get('submitted'),
    not session.get('submittedCode'), # Allow leaderboard access to non-multiplayer sessions
    session.hasPermissionsForMethod?(req.user, 'GET')
  ])
    throw new errors.Forbidden('Cannot access this session.')

  if session.get('dateFirstCompleted') and (not req.user?.isTeacher()) and (req.user?.id isnt session.get('creator'))
    cutoff = moment(session.get('dateFirstCompleted')).add(4, 'days')
    if cutoff.isAfter(new Date())
      yield session.update({$inc: {fourDayViewCount: 1}})
      
  res.status(200).send(session.toObject({req}))

module.exports = {
  getByHandle
}
