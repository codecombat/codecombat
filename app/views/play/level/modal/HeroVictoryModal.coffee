ModalView = require 'views/kinds/ModalView'
template = require 'templates/play/level/modal/hero-victory-modal'
Achievement = require 'models/Achievement'
CocoCollection = require 'collections/CocoCollection'
LocalMongo = require 'lib/LocalMongo'
utils = require 'lib/utils'
ThangType = require 'models/ThangType'

module.exports = class UnnamedView extends ModalView
  id: 'hero-victory-modal'
  template: template

  constructor: (options) ->
    super(options)
    @session = options.session
    @level = options.level
    achievements = new CocoCollection([], {
      url: "/db/achievement?related=#{@session.get('level').original}"
      model: Achievement
    })
    @thangTypes = {}
    @achievements = @supermodel.loadCollection(achievements, 'achievements').model
    @listenToOnce @achievements, 'sync', @onAchievementsLoaded
  
  onAchievementsLoaded: ->
    thangTypeOriginals = []
    for achievement in @achievements.models
      rewards = achievement.get('rewards')
      console.log 'rewards', rewards
      thangTypeOriginals.push rewards.heroes or []
      thangTypeOriginals.push rewards.items or []
    thangTypeOriginals = _.uniq _.flatten thangTypeOriginals
    console.log 'thang type originals?', thangTypeOriginals
    for thangTypeOriginal in thangTypeOriginals
      thangType = new ThangType()
      thangType.url = "/db/thang.type/#{thangTypeOriginal}/version"
      thangType.project = ['original', 'rasterIcon']
      @thangTypes[thangTypeOriginal] = @supermodel.loadModel(thangType, 'thang').model
    
  getRenderData: ->
    c = super()
    c.levelName = utils.i18n @level.attributes, 'name'
    for achievement in @achievements.models
      achievement.completed = LocalMongo.matchesQuery(@session.attributes, achievement.get('query'))
    c.achievements = @achievements.models
    c.thangTypes = @thangTypes
    return c 