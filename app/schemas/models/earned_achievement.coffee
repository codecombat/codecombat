c = require './../schemas'

module.exports =
  EarnedAchievementSchema =
    type: 'object'
    default:
      previouslyAchievedAmount: 0

    properties:
      user: c.objectId
        links:
          [
            {
              rel: 'extra'
              href: '/db/user/{($)}'
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
      triggeredBy: c.objectId()
      achievementName: type: 'string'
      created: type: ['date', 'string', 'number']
      changed: type: ['date', 'string', 'number'] # TODO: migrate timestamps and Date objects all to ISO strings 
      achievedAmount: type: 'number'
      earnedPoints: type: 'number'
      previouslyAchievedAmount: {type: 'number'}
      earnedRewards: c.RewardSchema 'awarded by this achievement to this user'
      notified: type: 'boolean'
