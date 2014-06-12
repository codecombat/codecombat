c = require './../schemas'

module.exports =
  EarnedAchievementSchema =
    type: 'object'
    properties:
      user: c.objectId
        links:
          [
            {
              rel: 'extra'
              href: "/db/user/{($)}"
            }
          ]
      achievement: c.objectId
        links:
          [
            {
              rel: 'extra'
              href: '/db/achievement/{($)}'
            }
          ]
      collection: type: 'string'
      achievementName: type: 'string'
      created: type: 'date'
      changed: type: 'date'
      achievedAmount: type: 'number'
      earnedPoints: type: 'number'
      previouslyAchievedAmount: {type: 'number', default: 0}
      notified: type: 'boolean'
