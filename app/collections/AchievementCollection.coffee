CocoCollection = require 'collections/CocoCollection'
Achievement = require 'models/Achievement'

module.exports = class AchievementCollection extends CocoCollection
  url: '/db/achievement'
  model: Achievement
