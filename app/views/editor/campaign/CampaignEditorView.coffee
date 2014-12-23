RootView = require 'views/core/RootView'
Campaign = require 'models/Campaign'
Level = require 'models/Level'
Achievement = require 'models/Achievement'
ThangType = require 'models/ThangType'
CampaignView = require 'views/play/CampaignView'
CocoCollection = require 'collections/CocoCollection'
treemaExt = require 'core/treema-ext'
utils = require 'core/utils'
SaveCampaignModal = require './SaveCampaignModal'
RelatedAchievementsCollection = require 'collections/RelatedAchievementsCollection'
CampaignLevelView = require './CampaignLevelView'

achievementProject = ['related', 'rewards', 'name', 'slug']
thangTypeProject = ['name', 'original', 'slug']

module.exports = class CampaignEditorView extends RootView
  id: "campaign-editor-view"
  template: require 'templates/editor/campaign/campaign-editor-view'
  className: 'editor'
  
  events:
    'click #save-button': 'onClickSaveButton'

  constructor: (options, @campaignHandle) ->
    super(options)
    
    # MIGRATION CODE
#    for level in levels
#      _.extend level, options[level.id]
#      level.slug = level.id
#      delete level.id
#      delete level.nextLevels
#      level.position = { x: level.x, y: level.y }
#      delete level.x
#      delete level.y
#      if level.unlocksHero
#        level.unlocks = [{
#          original: level.unlocksHero.originalID
#          type: 'hero'
#        }]
#      delete level.unlocksHero
#      campaign.levels[level.original] = level
#    @campaign = new Campaign(campaign)
    #------------------------------------------------
  
    @campaign = new Campaign({_id:@campaignHandle})
    
    #--------------- temporary migration to change thang type slugs to originals
    #- should keep around though for loading the names of items and heroes that are referenced
    #- just load names instead of slugs, though
    @sluggyThangs = new Backbone.Collection()
    @listenToOnce @campaign, 'sync', ->
      slugs = []
      for level in _.values(@campaign.get('levels'))
        slugs = slugs.concat(_.values(level.requiredGear)) if level.requiredGear
        slugs = slugs.concat(_.values(level.restrictedGear)) if level.restrictedGear 
        slugs = slugs.concat(level.allowedHeroes) if level.allowedHeroes
      slugs = _.uniq _.flatten slugs
      for slug in slugs
        thangType = new ThangType()
        thangType.setProjection(thangTypeProject)
        if utils.isID slug
          thangType.setURL("/db/thang.type/#{slug}/version")
        else
          thangType.setURL("/db/thang.type/#{slug}")
        @supermodel.loadModel(thangType, 'thang')
        @sluggyThangs.add(thangType)
    #---------------
    @supermodel.loadModel(@campaign, 'campaign')

    @levels = new CocoCollection([], {
      model: Level
      url: "/db/campaign/#{@campaignHandle}/levels"
      project: Campaign.denormalizedLevelProperties
    })
    @supermodel.loadCollection(@levels, 'levels')

    @achievements = new CocoCollection([], {
      model: Achievement
      url: "/db/campaign/#{@campaignHandle}/achievements"
      project: achievementProject
    })
    @supermodel.loadCollection(@achievements, 'achievements')
    
    @toSave = new Backbone.Collection()
    @listenToOnce @campaign, 'sync', @onFundamentalLoaded
    @listenToOnce @levels, 'sync', @onFundamentalLoaded
    @listenToOnce @achievements, 'sync', @onFundamentalLoaded

  onFundamentalLoaded: ->
    # load any levels which 
    return unless @campaign.loaded and @levels.loaded and @achievements.loaded
    for level in _.values(@campaign.get('levels'))
      model = @levels.findWhere(original: level.original)
      if not model
        model = new Level({})
        model.setProjection Campaign.denormalizedLevelProperties
        model.setURL("/db/level/#{level.original}/version")
        @levels.add @supermodel.loadModel(model, 'level').model
        achievements = new RelatedAchievementsCollection level.original
        achievements.setProjection achievementProject
        @supermodel.loadCollection achievements, 'achievements'
        @listenToOnce achievements, 'sync', ->
          @achievements.add(achievements.models)
      

  onLoaded: ->
    @toSave.add @campaign if @campaign.hasLocalChanges()
    campaignLevels = $.extend({}, @campaign.get('levels'))
    for level in @levels.models
      levelOriginal = level.get('original')
      campaignLevel = campaignLevels[levelOriginal]
      continue if not campaignLevel

      #--------------- temporary migrations
      if campaignLevel.restrictedGear
        for slot, value of campaignLevel.restrictedGear
          if _.isString(value)
            campaignLevel.restrictedGear[slot] = [value]
      #
      if campaignLevel.requiredGear
        for slot, value of campaignLevel.requiredGear
          if _.isString(value)
            campaignLevel.requiredGear[slot] = [value]
      #
      if campaignLevel.requiredGear
        for gear in _.values(campaignLevel.requiredGear)
          for slug, index in gear
            thang = @sluggyThangs.findWhere({slug: slug})
            continue unless thang
            gear[index] = thang.get('original')
      #
      if campaignLevel.restrictedGear
        for gear in _.values(campaignLevel.restrictedGear)
          for slug, index in gear
            thang = @sluggyThangs.findWhere({slug: slug})
            continue unless thang
            gear[index] = thang.get('original')
      #
      if campaignLevel.allowedHeroes
        for slug, index in campaignLevel.allowedHeroes
          thang = @sluggyThangs.findWhere({slug: slug})
          continue unless thang
          level.allowedHeroes[index] = thang.get('original')
      #---------------
        
      $.extend campaignLevel, _.omit(level.attributes, '_id')
      achievements = @achievements.where {'related': levelOriginal}
      rewards = []
      for achievement in achievements
        for rewardType, rewardArray of achievement.get('rewards')
          for reward in rewardArray
            rewardObject = { achievement: achievement.id }
            
            if rewardType is 'heroes'
              rewardObject.hero = reward
              thangType = new ThangType({}, {project: thangTypeProject})
              thangType.setURL("/db/thang.type/#{reward}/version")
              @supermodel.loadModel(thangType, 'thang')
                
            if rewardType is 'levels'
              rewardObject.level = reward
              if not @levels.findWhere({original: reward})
                level = new Level({}, {project: Campaign.denormalizedLevelProperties})
                level.setURL("/db/level/#{reward}/version")
                @supermodel.loadModel(level, 'level')
                
            if rewardType is 'items'
              rewardObject.item = reward
              thangType = new ThangType({}, {project: thangTypeProject})
              thangType.setURL("/db/thang.type/#{reward}/version")
              @supermodel.loadModel(thangType, 'thang')
              
            rewards.push rewardObject
      campaignLevel.rewards = rewards
      delete campaignLevel.unlocks
      campaignLevels[levelOriginal] = campaignLevel
      
    @campaign.set('levels', campaignLevels)
    
    for level in _.values campaignLevels
      model = @levels.findWhere {original: level.original}
      model.set key, level[key] for key in Campaign.denormalizedLevelProperties
#      @toSave.add model if model.hasLocalChanges()
#      @updateRewardsForLevel model, level.rewards

    super()

  getRenderData: ->
    c = super()
    c.campaign = @campaign
    c

  onClickSaveButton: ->
    @toSave.set @toSave.filter (m) -> m.hasLocalChanges()
    @openModalView new SaveCampaignModal({}, @toSave)
    
  afterRender: ->
    super()
    treemaOptions =
      schema: Campaign.schema
      data: $.extend({}, @campaign.attributes)
      callbacks:
        change: @onTreemaChanged
        select: @onTreemaSelectionChanged
        dblclick: @onTreemaDoubleClicked
      nodeClasses:
        levels: LevelsNode
        level: LevelNode
        campaigns: CampaignsNode
        campaign: CampaignNode
        achievement: AchievementNode
      supermodel: @supermodel

    @treema = @$el.find('#campaign-treema').treema treemaOptions
    @treema.build()
    @treema.open()
    @treema.childrenTreemas.levels?.open()

    @campaignView = new CampaignView({editorMode: true, supermodel: @supermodel}, @campaignHandle)
    @campaignView.highlightElement = _.noop # make it stop
    @listenTo @campaignView, 'level-moved', @onCampaignLevelMoved
    @listenTo @campaignView, 'adjacent-campaign-moved', @onAdjacentCampaignMoved
    @listenTo @campaignView, 'level-clicked', @onCampaignLevelClicked
    @insertSubView @campaignView
    
  onTreemaChanged: (e, nodes) =>
    for node in nodes
      path = node.getPath()
      if _.string.startsWith path, '/levels/'
        parts = path.split('/')
        original = parts[2]
        level = @supermodel.getModelByOriginal Level, original
        campaignLevel = @treema.get "/levels/#{original}"
        
        @updateRewardsForLevel level, campaignLevel.rewards
        
        level.set key, campaignLevel[key] for key in Campaign.denormalizedLevelProperties
        @toSave.add level if level.hasLocalChanges()
        
    @toSave.add @campaign
    @campaign.set key, value for key, value of @treema.data
    @campaignView.setCampaign(@campaign)

  onTreemaDoubleClicked: (e, node) =>
    path = node.getPath()
    return unless _.string.startsWith path, '/levels/'
    original = path.split('/')[2]
    level = @supermodel.getModelByOriginal Level, original
    @insertSubView new CampaignLevelView({}, level)

  onCampaignLevelMoved: (e) ->
    path = "levels/#{e.levelOriginal}/position"
    @treema.set path, e.position

  onAdjacentCampaignMoved: (e) ->
    path = "adjacentCampaigns/#{e.campaignID}/position"
    @treema.set path, e.position

  onCampaignLevelClicked: (levelOriginal) ->
    return unless levelTreema = @treema.childrenTreemas?.levels?.childrenTreemas?[levelOriginal]
    levelTreema.select()
#    levelTreema.open()

  updateRewardsForLevel: (level, rewards) ->
    achievements = @supermodel.getModels(Achievement)
    achievements = (a for a in achievements when a.get('related') is level.get('original'))
    for achievement in achievements
      rewardSubset = (r for r in rewards when r.achievement is achievement.id)
      oldRewards = achievement.get 'rewards'
      newRewards = {}
      
      heroes = _.compact((r.hero for r in rewardSubset))
      newRewards.heroes = heroes if heroes.length
      
      items = _.compact((r.item for r in rewardSubset))
      newRewards.items = items if items.length

      levels = _.compact((r.level for r in rewardSubset))
      newRewards.levels = levels if levels.length
      
      newRewards.gems = oldRewards.gems if oldRewards.gems
      achievement.set 'rewards', newRewards
      if achievement.hasLocalChanges()
        @toSave.add achievement

class LevelsNode extends TreemaObjectNode
  valueClass: 'treema-levels'
  @levels: {}
  
  buildValueForDisplay: (valEl, data) ->
    @buildValueForDisplaySimply valEl, ''+_.size(data)

  childPropertiesAvailable: -> @childSource

  childSource: (req, res) =>
    s = new Backbone.Collection([], {model:Level})
    s.url = '/db/level'
    s.fetch({data: {term:req.term, project: Campaign.denormalizedLevelProperties.join(',')}})
    s.once 'sync', (collection) =>
      for level in collection.models
        LevelsNode.levels[level.get('original')] = level
        @settings.supermodel.registerModel level
      mapped = ({label: r.get('name'), value: r.get('original')} for r in collection.models)
      res(mapped)


class LevelNode extends TreemaObjectNode
  valueClass: 'treema-level'
  buildValueForDisplay: (valEl, data) ->
    @buildValueForDisplaySimply valEl, data.name
    
  populateData: ->
    return if @data.name?
    data = _.pick LevelsNode.levels[@keyForParent].attributes, Campaign.denormalizedLevelProperties
    _.extend @data, data

class CampaignsNode extends TreemaObjectNode
  valueClass: 'treema-campaigns'
  @campaigns: {}

  buildValueForDisplay: (valEl, data) ->
    @buildValueForDisplaySimply valEl, ''+_.size(data)

  childPropertiesAvailable: -> @childSource

  childSource: (req, res) =>
    s = new Backbone.Collection([], {model:Campaign})
    s.url = '/db/campaign'
    s.fetch({data: {term:req.term, project: campaign.denormalizedCampaignProperties}})
    s.once 'sync', (collection) ->
      CampaignsNode.campaigns[campaign.id] = campaign for campaign in collection.models
      mapped = ({label: r.get('name'), value: r.id} for r in collection.models)
      res(mapped)


class CampaignNode extends TreemaObjectNode
  valueClass: 'treema-campaign'
  buildValueForDisplay: (valEl, data) ->
    @buildValueForDisplaySimply valEl, data.name

  populateData: ->
    return if @data.name?
    data = _.pick CampaignsNode.campaigns[@keyForParent].attributes, Campaign.denormalizedCampaignProperties
    _.extend @data, data
    
class AchievementNode extends treemaExt.IDReferenceNode
  buildSearchURL: (term) -> "#{@url}?term=#{term}&project=#{achievementProject.join(',')}"



    
#campaign = {
#  name: 'Dungeon'
#  levels: {}
#}
#
#
#levels = [
#  {
#    name: 'Dungeons of Kithgard'
#    type: 'hero'
#    id: 'dungeons-of-kithgard'
#    original: '5411cb3769152f1707be029c'
#    description: 'Grab the gem, but touch nothing else. Start here.'
#    x: 14
#    y: 15.5
#    nextLevels:
#      continue: 'gems-in-the-deep'
#  }
#  {
#    name: 'Gems in the Deep'
#    type: 'hero'
#    id: 'gems-in-the-deep'
#    original: '54173c90844506ae0195a0b4'
#    description: 'Quickly collect the gems; you will need them.'
#    x: 29
#    y: 12
#    nextLevels:
#      continue: 'shadow-guard'
#  }
#  {
#    name: 'Shadow Guard'
#    type: 'hero'
#    id: 'shadow-guard'
#    original: '54174347844506ae0195a0b8'
#    description: 'Evade the Kithgard minion.'
#    x: 40.54
#    y: 11.03
#    nextLevels:
#      continue: 'forgetful-gemsmith'
#  }
#  {
#    name: 'Kounter Kithwise'
#    type: 'hero'
#    id: 'kounter-kithwise'
#    original: '54527a6257e83800009730c7'
#    description: 'Practice your evasion skills with more guards.'
#    x: 35.37
#    y: 20.61
#    nextLevels:
#      continue: 'crawlways-of-kithgard'
#    practice: true
#    requiresSubscription: true
#  }
#  {
#    name: 'Crawlways of Kithgard'
#    type: 'hero'
#    id: 'crawlways-of-kithgard'
#    original: '545287ef57e83800009730d5'
#    description: 'Dart in and grab the gem–at the right moment.'
#    x: 36.48
#    y: 29.03
#    nextLevels:
#      continue: 'forgetful-gemsmith'
#    practice: true
#    requiresSubscription: true
#  }
#  {
#    name: 'Forgetful Gemsmith'
#    type: 'hero'
#    id: 'forgetful-gemsmith'
#    original: '544a98f62d002f0000fe331a'
#    description: 'Grab even more gems as you practice moving.'
#    x: 54.98
#    y: 10.53
#    nextLevels:
#      continue: 'true-names'
#  }
#  {
#    name: 'True Names'
#    type: 'hero'
#    id: 'true-names'
#    original: '541875da4c16460000ab990f'
#    description: 'Learn an enemy\'s true name to defeat it.'
#    x: 68.44
#    y: 10.70
#    nextLevels:
#      continue: 'the-raised-sword'
#    unlocksHero: {
#      img: '/file/db/thang.type/53e12be0d042f23505c3023b/portrait.png'
#      originalID: '53e12be0d042f23505c3023b'
#    }
#  }
#  {
#    name: 'Favorable Odds'
#    type: 'hero'
#    id: 'favorable-odds'
#    original: '5452972f57e83800009730de'
#    description: 'Test out your battle skills by defeating more munchkins.'
#    x: 88.25
#    y: 14.92
#    nextLevels:
#      continue: 'the-raised-sword'
#    practice: true
#    requiresSubscription: true
#  }
#  {
#    name: 'The Raised Sword'
#    type: 'hero'
#    id: 'the-raised-sword'
#    original: '5418aec24c16460000ab9aa6'
#    description: 'Learn to equip yourself for combat.'
#    x: 81.51
#    y: 17.92
#    nextLevels:
#      continue: 'haunted-kithmaze'
#  }
#  {
#    name: 'Haunted Kithmaze'
#    type: 'hero'
#    id: 'haunted-kithmaze'
#    original: '545a5914d820eb0000f6dc0a'
#    description: 'The builders of Kithgard constructed many mazes to confuse travelers.'
#    x: 78
#    y: 29
#    nextLevels:
#      continue: 'the-second-kithmaze'
#  }
#  {
#    name: 'Riddling Kithmaze'
#    type: 'hero'
#    id: 'riddling-kithmaze'
#    original: '5418b9d64c16460000ab9ab4'
#    description: 'If at first you go astray, change your loop to find the way.'
#    x: 69.97
#    y: 28.03
#    nextLevels:
#      continue: 'descending-further'
#    practice: true
#    requiresSubscription: true
#  }
#  {
#    name: 'Descending Further'
#    type: 'hero'
#    id: 'descending-further'
#    original: '5452a84d57e83800009730e4'
#    description: 'Another day, another maze.'
#    x: 61.68
#    y: 22.80
#    nextLevels:
#      continue: 'the-second-kithmaze'
#    practice: true
#    requiresSubscription: true
#  }
#  {
#    name: 'The Second Kithmaze'
#    type: 'hero'
#    id: 'the-second-kithmaze'
#    original: '5418cf256bae62f707c7e1c3'
#    description: 'Many have tried, few have found their way through this maze.'
#    x: 54.49
#    y: 26.49
#    nextLevels:
#      continue: 'dread-door'
#  }
#  {
#    name: 'Dread Door'
#    type: 'hero'
#    id: 'dread-door'
#    original: '5418d40f4c16460000ab9ac2'
#    description: 'Behind a dread door lies a chest full of riches.'
#    x: 60.52
#    y: 33.70
#    nextLevels:
#      continue: 'known-enemy'
#  }
#  {
#    name: 'Known Enemy'
#    type: 'hero'
#    id: 'known-enemy'
#    original: '5452adea57e83800009730ee'
#    description: 'Begin to use variables in your battles.'
#    x: 67
#    y: 39
#    nextLevels:
#      continue: 'master-of-names'
#  }
#  {
#    name: 'Master of Names'
#    type: 'hero'
#    id: 'master-of-names'
#    original: '5452c3ce57e83800009730f7'
#    description: 'Use your glasses to defend yourself from the Kithmen.'
#    x: 75
#    y: 46
#    nextLevels:
#      continue: 'lowly-kithmen'
#  }
#  {
#    name: 'Lowly Kithmen'
#    type: 'hero'
#    id: 'lowly-kithmen'
#    original: '541b24511ccc8eaae19f3c1f'
#    description: 'Now that you can see them, they\'re everywhere!'
#    x: 85
#    y: 40
#    nextLevels:
#      continue: 'closing-the-distance'
#  }
#  {
#    name: 'Closing the Distance'
#    type: 'hero'
#    id: 'closing-the-distance'
#    original: '541b288e1ccc8eaae19f3c25'
#    description: 'Kithmen are not the only ones to stand in your way.'
#    x: 93
#    y: 47
#    nextLevels:
#      continue: 'the-final-kithmaze'
#  }
#  {
#    name: 'Tactical Strike'
#    type: 'hero'
#    id: 'tactical-strike'
#    original: '5452cfa706a59e000067e4f5'
#    description: 'They\'re, uh, coming right for us! Sneak up behind them.'
#    x: 83.23
#    y: 52.73
#    nextLevels:
#      continue: 'the-final-kithmaze'
#    practice: true
#    requiresSubscription: true
#  }
#  {
#    name: 'The Final Kithmaze'
#    type: 'hero'
#    id: 'the-final-kithmaze'
#    original: '541b434e1ccc8eaae19f3c33'
#    description: 'To escape you must find your way through an Elder Kithman\'s maze.'
#    x: 86.95
#    y: 64.70
#    nextLevels:
#      continue: 'kithgard-gates'
#  }
#  {
#    name: 'The Gauntlet'
#    type: 'hero'
#    id: 'the-gauntlet'
#    original: '5452d8b906a59e000067e4fa'
#    description: 'Rush for the stairs, battling foes at every turn.'
#    x: 76.50
#    y: 72.69
#    nextLevels:
#      continue: 'kithgard-gates'
#    practice: true
#    requiresSubscription: true
#  }
#  {
#    name: 'Kithgard Gates'
#    type: 'hero'
#    id: 'kithgard-gates'
#    original: '541c9a30c6362edfb0f34479'
#    description: 'Escape the Kithgard dungeons and don\'t let the guardians get you.'
#    x: 89
#    y: 82
#    nextLevels:
#      continue: 'defense-of-plainswood'
#  }
#  {
#    name: 'Cavern Survival'
#    type: 'hero-ladder'
#    id: 'cavern-survival'
#    original: '544437e0645c0c0000c3291d'
#    description: 'Stay alive longer than your opponent amidst hordes of ogres!'
#    x: 17.54
#    y: 78.39
#  }
#]
#
#options =
#  'dungeons-of-kithgard':
#    disableSpaces: true
#    hidesSubmitUntilRun: true
#    hidesPlayButton: true
#    hidesRunShortcut: true
#    hidesHUD: true
#    hidesSay: true
#    hidesCodeToolbar: true
#    hidesRealTimePlayback: true
#    requiredGear: {feet: 'simple-boots'}
#    restrictedGear: {feet: 'leather-boots'}
#    requiredCode: ['moveRight']
#  'gems-in-the-deep':
#    disableSpaces: true
#    hidesSubmitUntilRun: true
#    hidesPlayButton: true
#    hidesRunShortcut: true
#    hidesHUD: true
#    hidesSay: true
#    hidesCodeToolbar: true
#    hidesRealTimePlayback: true
#    requiredGear: {feet: 'simple-boots'}
#    restrictedGear: {feet: 'leather-boots'}
#  'shadow-guard':
#    disableSpaces: true
#    hidesSubmitUntilRun: true
#    hidesPlayButton: true
#    hidesRunShortcut: true
#    hidesHUD: true
#    hidesSay: true
#    hidesCodeToolbar: true
#    hidesRealTimePlayback: true
#    requiredGear: {feet: 'simple-boots'}
#    restrictedGear: {feet: 'leather-boots', 'right-hand': 'simple-sword'}
#  'kounter-kithwise':
#    disableSpaces: true
#    hidesPlayButton: true
#    hidesRunShortcut: true
#    hidesHUD: true
#    hidesSay: true
#    hidesCodeToolbar: true
#    hidesRealTimePlayback: true
#    requiredGear: {feet: 'simple-boots'}
#    restrictedGear: {feet: 'leather-boots', 'right-hand': 'simple-sword', 'programming-book': 'programmaticon-i'}
#  'crawlways-of-kithgard':
#    hidesPlayButton: true
#    hidesRunShortcut: true
#    hidesHUD: true
#    hidesSay: true
#    hidesCodeToolbar: true
#    hidesRealTimePlayback: true
#    requiredGear: {feet: 'simple-boots'}
#    restrictedGear: {feet: 'leather-boots', 'right-hand': 'simple-sword', 'programming-book': 'programmaticon-i'}
#  'forgetful-gemsmith':
#    disableSpaces: true
#    hidesPlayButton: true
#    hidesRunShortcut: true
#    hidesHUD: true
#    hidesSay: true
#    hidesCodeToolbar: true
#    hidesRealTimePlayback: true
#    requiredGear: {feet: 'simple-boots'}
#    restrictedGear: {feet: 'leather-boots', 'programming-book': 'programmaticon-i'}
#  'true-names':
#    disableSpaces: true
#    hidesPlayButton: true
#    hidesRunShortcut: true
#    hidesHUD: true
#    hidesSay: true
#    hidesCodeToolbar: true
#    hidesRealTimePlayback: true
#    requiredGear: {feet: 'simple-boots', 'right-hand': 'simple-sword', waist: 'leather-belt'}
#    restrictedGear: {feet: 'leather-boots', 'programming-book': 'programmaticon-i'}
#    requiredCode: ['Brak']
#  'favorable-odds':
#    disableSpaces: true
#    hidesPlayButton: true
#    hidesRunShortcut: true
#    hidesHUD: true
#    hidesSay: true
#    hidesCodeToolbar: true
#    hidesRealTimePlayback: true
#    requiredGear: {feet: 'simple-boots', 'right-hand': 'simple-sword'}
#    restrictedGear: {feet: 'leather-boots', 'programming-book': 'programmaticon-i'}
#  'the-raised-sword':
#    disableSpaces: true
#    hidesPlayButton: true
#    hidesRunShortcut: true
#    hidesHUD: true
#    hidesSay: true
#    hidesCodeToolbar: true
#    hidesRealTimePlayback: true
#    requiredGear: {feet: 'simple-boots', 'right-hand': 'simple-sword', torso: 'tarnished-bronze-breastplate'}
#    restrictedGear: {feet: 'leather-boots', 'programming-book': 'programmaticon-i'}
#  'the-first-kithmaze':
#    hidesRunShortcut: true
#    hidesHUD: true
#    hidesSay: true
#    hidesCodeToolbar: true
#    hidesRealTimePlayback: true
#    requiredGear: {feet: 'simple-boots', 'programming-book': 'programmaticon-i'}
#    restrictedGear: {feet: 'leather-boots'}
#    requiredCode: ['loop']
#  'haunted-kithmaze':
#    hidesRunShortcut: true
#    hidesHUD: true
#    hidesSay: true
#    hidesCodeToolbar: true
#    hidesRealTimePlayback: true
#    moveRightLoopSnippet: true
#    requiredGear: {feet: 'simple-boots', 'programming-book': 'programmaticon-i'}
#    restrictedGear: {feet: 'leather-boots'}
#    requiredCode: ['loop']
#  'descending-further':
#    hidesHUD: true
#    hidesSay: true
#    hidesCodeToolbar: true
#    hidesRealTimePlayback: true
#    requiredGear: {feet: 'simple-boots', 'programming-book': 'programmaticon-i'}
#    restrictedGear: {feet: 'leather-boots'}
#  'the-second-kithmaze':
#    hidesHUD: true
#    hidesSay: true
#    hidesCodeToolbar: true
#    hidesRealTimePlayback: true
#    moveRightLoopSnippet: true
#    requiredGear: {feet: 'simple-boots', 'programming-book': 'programmaticon-i'}
#    restrictedGear: {feet: 'leather-boots'}
#  'dread-door':
#    hidesHUD: true
#    hidesSay: true
#    hidesCodeToolbar: true
#    hidesRealTimePlayback: true
#    requiredGear: {'right-hand': 'simple-sword', 'programming-book': 'programmaticon-i'}
#    restrictedGear: {feet: 'leather-boots'}
#  'known-enemy':
#    hidesHUD: true
#    hidesSay: true
#    hidesCodeToolbar: true
#    hidesRealTimePlayback: true
#    requiredGear: {'right-hand': 'simple-sword', 'programming-book': 'programmaticon-i', torso: 'tarnished-bronze-breastplate'}
#    restrictedGear: {feet: 'leather-boots'}
#    suspectCode: [{name: 'enemy-in-quotes', pattern: '[\'"]enemy'}]  # '
#  'master-of-names':
#    hidesHUD: true
#    hidesSay: true
#    hidesCodeToolbar: true
#    hidesRealTimePlayback: true
#    requiredGear: {feet: 'simple-boots', 'right-hand': 'simple-sword', 'programming-book': 'programmaticon-i', eyes: 'crude-glasses', torso: 'tarnished-bronze-breastplate'}
#    restrictedGear: {feet: 'leather-boots'}
#    requiredCode: ['findNearestEnemy']
#    suspectCode: [{name: 'lone-find-nearest-enemy', pattern: '^[ ]*(self|this|@)?[:.]?findNearestEnemy()'}]
#  'lowly-kithmen':
#    hidesHUD: true
#    hidesSay: true
#    hidesCodeToolbar: true
#    hidesRealTimePlayback: true
#    requiredGear: {feet: 'simple-boots', 'right-hand': 'simple-sword', 'programming-book': 'programmaticon-i', eyes: 'crude-glasses', torso: 'tarnished-bronze-breastplate'}
#    restrictedGear: {feet: 'leather-boots'}
#    requiredCode: ['findNearestEnemy']
#    suspectCode: [{name: 'lone-find-nearest-enemy', pattern: '^[ ]*(self|this|@)?[:.]?findNearestEnemy()'}]
#  'closing-the-distance':
#    hidesHUD: true
#    hidesSay: true
#    hidesCodeToolbar: true
#    hidesRealTimePlayback: true
#    requiredGear: {feet: 'simple-boots', 'right-hand': 'simple-sword', torso: 'tarnished-bronze-breastplate', eyes: 'crude-glasses'}
#    restrictedGear: {feet: 'leather-boots'}
#    suspectCode: [{name: 'lone-find-nearest-enemy', pattern: '^[ ]*(self|this|@)?[:.]?findNearestEnemy()'}]
#  'tactical-strike':
#    hidesHUD: true
#    hidesSay: true
#    hidesCodeToolbar: true
#    hidesRealTimePlayback: true
#    requiredGear: {feet: 'simple-boots', 'right-hand': 'simple-sword', torso: 'tarnished-bronze-breastplate', eyes: 'crude-glasses'}
#    restrictedGear: {feet: 'leather-boots'}
#    suspectCode: [{name: 'lone-find-nearest-enemy', pattern: '^[ ]*(self|this|@)?[:.]?findNearestEnemy()'}]
#  'the-final-kithmaze':
#    hidesHUD: true
#    hidesSay: true
#    hidesCodeToolbar: true
#    hidesRealTimePlayback: true
#    requiredGear: {feet: 'simple-boots', 'right-hand': 'simple-sword', torso: 'tarnished-bronze-breastplate', 'programming-book': 'programmaticon-i', eyes: 'crude-glasses'}
#    suspectCode: [{name: 'lone-find-nearest-enemy', pattern: '^[ ]*(self|this|@)?[:.]?findNearestEnemy()'}]
#  'the-gauntlet':
#    hidesHUD: true
#    hidesSay: true
#    hidesCodeToolbar: true
#    hidesRealTimePlayback: true
#    requiredGear: {feet: 'simple-boots', 'right-hand': 'simple-sword', torso: 'tarnished-bronze-breastplate', 'programming-book': 'programmaticon-i', eyes: 'crude-glasses'}
#    restrictedGear: {feet: 'leather-boots', 'right-hand': 'crude-builders-hammer'}
#    suspectCode: [{name: 'lone-find-nearest-enemy', pattern: '^[ ]*(self|this|@)?[:.]?findNearestEnemy()'}]
#  'kithgard-gates':
#    hidesSay: true
#    hidesCodeToolbar: true
#    hidesRealTimePlayback: true
#    requiredGear: {feet: 'simple-boots', 'right-hand': 'crude-builders-hammer', torso: 'tarnished-bronze-breastplate'}
#    restrictedGear: {'right-hand': 'simple-sword'}
#  'defense-of-plainswood':
#    hidesRealTimePlayback: true
#    hidesCodeToolbar: true
#    requiredGear: {feet: 'simple-boots', 'right-hand': 'crude-builders-hammer'}
#    restrictedGear: {'right-hand': 'simple-sword'}
#  'winding-trail':
#    hidesRealTimePlayback: true
#    hidesCodeToolbar: true
#    requiredGear: {feet: 'leather-boots', 'right-hand': 'crude-builders-hammer'}
#    restrictedGear: {feet: 'simple-boots', 'right-hand': 'simple-sword'}
#  'patrol-buster':
#    hidesRealTimePlayback: true
#    hidesCodeToolbar: true
#    requiredGear: {feet: 'leather-boots', 'right-hand': 'simple-sword', 'programming-book': 'programmaticon-ii', eyes: 'crude-glasses'}
#    restrictedGear: {feet: 'simple-boots', 'right-hand': 'crude-builders-hammer', 'programming-book': 'programmaticon-i'}
#  'endangered-burl':
#    hidesRealTimePlayback: true
#    hidesCodeToolbar: true
#    requiredGear: {feet: 'leather-boots', 'right-hand': 'simple-sword', 'programming-book': 'programmaticon-ii', eyes: 'crude-glasses'}
#    restrictedGear: {feet: 'simple-boots', 'right-hand': 'crude-builders-hammer', 'programming-book': 'programmaticon-i'}
#  'village-guard':
#    hidesCodeToolbar: true
#    lockDefaultCode: true
#    requiredGear: {feet: 'leather-boots', 'right-hand': 'simple-sword', 'programming-book': 'programmaticon-ii', eyes: 'crude-glasses'}
#    restrictedGear: {feet: 'simple-boots', 'right-hand': 'crude-builders-hammer', 'programming-book': 'programmaticon-i'}
#  'thornbush-farm':
#    hidesCodeToolbar: true
#    lockDefaultCode: true
#    requiredGear: {feet: 'leather-boots', 'right-hand': 'crude-builders-hammer', 'programming-book': 'programmaticon-ii', eyes: 'crude-glasses'}
#    restrictedGear: {feet: 'simple-boots', 'right-hand': 'simple-sword', 'programming-book': 'programmaticon-i'}
#    requiredCode: ['topEnemy']
#  'back-to-back':
#    hidesCodeToolbar: true
#    requiredGear: {feet: 'leather-boots', torso: 'tarnished-bronze-breastplate', waist: 'leather-belt', 'programming-book': 'programmaticon-ii', eyes: 'crude-glasses', 'right-hand': 'simple-sword', 'left-hand': 'wooden-shield'}
#    restrictedGear: {feet: 'simple-boots', 'right-hand': 'crude-builders-hammer', 'programming-book': 'programmaticon-i'}
#  'ogre-encampment':
#    requiredGear: {torso: 'tarnished-bronze-breastplate', waist: 'leather-belt', 'programming-book': 'programmaticon-ii', eyes: 'crude-glasses', 'right-hand': 'simple-sword', 'left-hand': 'wooden-shield'}
#    restrictedGear: {feet: 'simple-boots', 'right-hand': 'crude-builders-hammer', 'programming-book': 'programmaticon-i'}
#  'woodland-cleaver':
#    requiredGear: {torso: 'tarnished-bronze-breastplate', waist: 'leather-belt', 'programming-book': 'programmaticon-ii', eyes: 'crude-glasses', 'right-hand': 'long-sword', 'left-hand': 'wooden-shield', wrists: 'sundial-wristwatch', feet: 'leather-boots'}
#    restrictedGear: {feet: 'simple-boots', 'right-hand': 'simple-sword', 'programming-book': 'programmaticon-i'}
#  'shield-rush':
#    requiredGear: {torso: 'tarnished-bronze-breastplate', waist: 'leather-belt', 'programming-book': 'programmaticon-ii', eyes: 'crude-glasses', 'right-hand': 'long-sword', 'left-hand': 'bronze-shield', wrists: 'sundial-wristwatch'}
#    restrictedGear: {'left-hand': 'wooden-shield', 'programming-book': 'programmaticon-i'}
#
## Warrior branch
#  'peasant-protection':
#    requiredGear: {torso: 'tarnished-bronze-breastplate', waist: 'leather-belt', 'programming-book': 'programmaticon-ii', eyes: 'wooden-glasses', 'right-hand': 'long-sword', 'left-hand': 'bronze-shield', wrists: 'sundial-wristwatch'}
#    restrictedGear: {eyes: 'crude-glasses', 'programming-book': 'programmaticon-i'}
#  'munchkin-swarm':
#    requiredGear: {torso: 'tarnished-bronze-breastplate', waist: 'leather-belt', 'programming-book': 'programmaticon-ii', eyes: 'wooden-glasses', 'right-hand': 'long-sword', 'left-hand': 'bronze-shield', wrists: 'sundial-wristwatch'}
#    restrictedGear: {'programming-book': 'programmaticon-i', eyes: 'crude-glasses'}
#
## Ranger branch
#  'munchkin-harvest':
#    requiredGear: {waist: 'leather-belt', 'programming-book': 'programmaticon-ii', eyes: 'wooden-glasses', 'right-hand': 'long-sword', 'left-hand': 'bronze-shield', wrists: 'sundial-wristwatch'}
#    restrictedGear: {'programming-book': 'programmaticon-i'}
#    allowedHeroes: ['captain', 'knight', 'samurai']
#  'swift-dagger':
#    requiredGear: {waist: 'leather-belt', 'programming-book': 'programmaticon-ii', eyes: 'wooden-glasses', 'right-hand': 'crude-crossbow', 'left-hand': 'crude-dagger', wrists: 'sundial-wristwatch'}
#    restrictedGear: {eyes: 'crude-glasses', 'programming-book': 'programmaticon-i'}
#    allowedHeroes: ['ninja', 'trapper', 'forest-archer']
#  'shrapnel':
#    requiredGear: {waist: 'leather-belt', 'programming-book': 'programmaticon-ii', eyes: 'wooden-glasses', 'right-hand': 'crude-crossbow', 'left-hand': 'weak-charge', wrists: 'sundial-wristwatch'}
#    restrictedGear: {eyes: 'crude-glasses', 'left-hand': 'crude-dagger', 'programming-book': 'programmaticon-i'}
#    allowedHeroes: ['ninja', 'trapper', 'forest-archer']
#
## Wizard branch
#  'arcane-ally':
#    requiredGear: {waist: 'leather-belt', 'programming-book': 'programmaticon-ii', eyes: 'wooden-glasses', 'right-hand': 'long-sword', 'left-hand': 'bronze-shield', wrists: 'sundial-wristwatch'}
#    restrictedGear: {eyes: 'crude-glasses', 'programming-book': 'programmaticon-i'}
#    allowedHeroes: ['captain', 'knight', 'samurai']
#  'touch-of-death':
#    requiredGear: {waist: 'leather-belt', 'programming-book': 'programmaticon-ii', eyes: 'wooden-glasses', 'right-hand': 'enchanted-stick', 'left-hand': 'unholy-tome-i', wrists: 'sundial-wristwatch'}
#    restrictedGear: {'programming-book': 'programmaticon-i', eyes: 'crude-glasses'}
#    allowedHeroes: ['librarian', 'potion-master', 'sorcerer']
#  'bonemender':
#    requiredGear: {waist: 'leather-belt', 'programming-book': 'programmaticon-ii', eyes: 'wooden-glasses', 'right-hand': 'enchanted-stick', 'left-hand': 'book-of-life-i', wrists: 'sundial-wristwatch'}
#    restrictedGear: {'left-hand': 'unholy-tome-i', 'programming-book': 'programmaticon-i', eyes: 'crude-glasses'}
#    requiredCode: ['canCast']
#    allowedHeroes: ['librarian', 'potion-master', 'sorcerer']
#
#  'coinucopia':
#    requiredGear: {'programming-book': 'programmaticon-ii', feet: 'leather-boots', flag: 'basic-flags'}
#    restrictedGear: {'programming-book': 'programmaticon-i', eyes: 'crude-glasses'}
#  'copper-meadows':
#    requiredGear: {'programming-book': 'programmaticon-ii', feet: 'leather-boots', flag: 'basic-flags', eyes: 'wooden-glasses'}
#    restrictedGear: {'programming-book': 'programmaticon-i', eyes: 'crude-glasses'}
#  'drop-the-flag':
#    requiredGear: {'programming-book': 'programmaticon-ii', feet: 'leather-boots', flag: 'basic-flags', eyes: 'wooden-glasses', 'right-hand': 'crude-builders-hammer'}
#    restrictedGear: {'right-hand': 'long-sword', 'programming-book': 'programmaticon-i', eyes: 'crude-glasses'}
#  'deadly-pursuit':
#    requiredGear: {'programming-book': 'programmaticon-ii', feet: 'leather-boots', flag: 'basic-flags', eyes: 'wooden-glasses', 'right-hand': 'crude-builders-hammer'}
#    restrictedGear: {'right-hand': 'long-sword', 'programming-book': 'programmaticon-i', eyes: 'crude-glasses'}
#  'rich-forager':
#    requiredGear: {'programming-book': 'programmaticon-ii', feet: 'leather-boots', flag: 'basic-flags', eyes: 'wooden-glasses', torso: 'tarnished-bronze-breastplate', 'right-hand': 'long-sword', 'left-hand': 'bronze-shield'}
#    restrictedGear: {'right-hand': 'crude-builders-hammer', 'programming-book': 'programmaticon-i', eyes: 'crude-glasses'}
#  'multiplayer-treasure-grove':
#    requiredGear: {'programming-book': 'programmaticon-ii', feet: 'leather-boots', flag: 'basic-flags', eyes: 'wooden-glasses', torso: 'tarnished-bronze-breastplate'}
#    restrictedGear: {'programming-book': 'programmaticon-i', eyes: 'crude-glasses'}
#  'siege-of-stonehold':
#    requiredGear: {}
#    restrictedGear: {}
#
## Desert
#  'the-dunes':
#    requiredGear: {}
#    restrictedGear: {}
#  'the-mighty-sand-yak':
#    requiredGear: {}
#    restrictedGear: {}
#  'oasis':
#    requiredGear: {}
#    restrictedGear: {}
