Achievement = require './Achievement'
Handler = require '../commons/Handler'

class AchievementHandler extends Handler
  modelClass: Achievement

  # Used to determine which properties requests may edit
  editableProperties: ['name', 'query', 'worth', 'collection', 'description', 'userField', 'proportionalTo', 'icon', 'function']
  jsonSchema = require '../../app/schemas/models/achievement.coffee'

  hasAccess: (req) ->
    req.method is 'GET' or req.user?.isAdmin()

module.exports = new AchievementHandler()
