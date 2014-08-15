CocoModel = require './CocoModel'
utils = require '../lib/utils'

module.exports = class EarnedAchievement extends CocoModel
  @className: 'EarnedAchievement'
  @schema: require 'schemas/models/earned_achievement'
  urlRoot: '/db/earnedachievement'
