CocoModel = require './CocoModel'
schema = require 'schemas/models/campaign.schema'
Level = require 'models/Level'
CocoCollection = require 'collections/CocoCollection'

module.exports = class Campaign extends CocoModel
  @className: 'Campaign'
  @schema: schema
  urlRoot: '/db/campaign'
  saveBackups: true
  @denormalizedLevelProperties: _.keys(_.omit(schema.properties.levels.additionalProperties.properties, ['unlocks', 'position', 'rewards']))
  @denormalizedCampaignProperties: ['name', 'i18n', 'slug']

  statsForSessions: (sessions) ->
    return null unless sessions
    stats = {}
    sessions = sessions.models or sessions
    sessions = _.sortBy sessions, (s) -> s.get('changed')
    levels = _.values(@get('levels'))
    levels = (level for level in levels when not _.contains(level.type, 'ladder'))
    levelOriginals = _.pluck(levels, 'original')
    sessionOriginals = (session.get('level').original for session in sessions when session.get('state').complete)
    levelsLeft = _.size(_.difference(levelOriginals, sessionOriginals))
    lastSession = _.last(sessions)
    stats.levels = {
      size: _.size(levels)
      left: levelsLeft
      done: levelsLeft is 0
      numDone: _.size(levels) - levelsLeft
      pctDone: (100 * (_.size(levels) - levelsLeft) / _.size(levels)).toFixed(1) + '%'
      lastPlayed: if lastSession then _.findWhere levels, { original: lastSession.get('level').original } else null
      first: _.first(levels)
      arena: _.find _.values(@get('levels')), (level) -> _.contains(level.type, 'ladder')
    }
    sum = (nums) -> _.reduce(nums, (s, num) -> s + num) or 0
    stats.playtime = sum((session.get('playtime') or 0 for session in sessions))
    return stats