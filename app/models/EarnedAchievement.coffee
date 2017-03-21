CocoModel = require './CocoModel'
utils = require '../core/utils'

module.exports = class EarnedAchievement extends CocoModel
  @className: 'EarnedAchievement'
  @schema: require 'schemas/models/earned_achievement'
  urlRoot: '/db/earned_achievement'
  
  save: ->
    @unset('earnedRewards') if @get('earnedRewards') is null
    super(arguments...)
