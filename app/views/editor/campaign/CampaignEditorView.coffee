require('app/styles/editor/campaign/campaign-editor-view.sass')
RootView = require 'views/core/RootView'
Campaign = require 'models/Campaign'
Level = require 'models/Level'
Achievement = require 'models/Achievement'
ThangType = require 'models/ThangType'
CampaignView = require 'views/play/CampaignView'
CocoCollection = require 'collections/CocoCollection'
require('lib/setupTreema')
treemaExt = require 'core/treema-ext'
utils = require 'core/utils'
RelatedAchievementsCollection = require 'collections/RelatedAchievementsCollection'
CampaignAnalyticsModal = require './CampaignAnalyticsModal'
CampaignLevelView = require './CampaignLevelView'
SaveCampaignModal = require './SaveCampaignModal'
PatchesView = require 'views/editor/PatchesView'
RevertModal = require 'views/modal/RevertModal'
modelDeltas = require 'lib/modelDeltas'
require('vendor/scripts/jquery-ui-1.11.1.custom')
require('vendor/styles/jquery-ui-1.11.1.custom.css')

require 'lib/game-libraries'

achievementProject = ['related', 'rewards', 'name', 'slug']
thangTypeProject = ['name', 'original']

module.exports = class CampaignEditorView extends RootView
  id: "campaign-editor-view"
  template: require 'templates/editor/campaign/campaign-editor-view'
  className: 'editor'

  events:
    'click #analytics-button': 'onClickAnalyticsButton'
    'click #save-button': 'onClickSaveButton'
    'click #patches-button': 'onClickPatches'
    'click [data-toggle="coco-modal"][data-target="modal/RevertModal"]': 'openRevertModal'

  subscriptions:
    'editor:campaign-analytics-modal-closed' : 'onAnalyticsModalClosed'

  constructor: (options, @campaignHandle) ->
    super(options)
    @campaign = new Campaign({_id:@campaignHandle})
    @supermodel.loadModel(@campaign)
    @listenToOnce @campaign, 'sync', (model, response, jqXHR) ->
      @campaign.set '_id', response._id
      @campaign.url = -> '/db/campaign/' + @id

    # Save reference to data used by anlytics modal so it persists across modal open/closes.
    @campaignAnalytics = {}

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
    @listenToOnce @campaign ,'sync', @loadThangTypeNames
    @listenToOnce @campaign, 'sync', @onFundamentalLoaded
    @listenToOnce @levels, 'sync', @onFundamentalLoaded
    @listenToOnce @achievements, 'sync', @onFundamentalLoaded

  openRevertModal: (e) ->
    e.stopPropagation()
    @openModalView new RevertModal()

  onLeaveMessage: ->
    for model in @toSave.models
      diff = modelDeltas.getDelta(model)
      if _.size(diff)
        console.log 'model, diff', model, diff
        return 'You have changes!'

  loadThangTypeNames: ->
    # Load the names of the ThangTypes that this level's Treema nodes might want to display.
    originals = []
    for level in _.values(@campaign.get('levels'))
      originals = originals.concat(_.values(level.requiredGear)) if level.requiredGear
      originals = originals.concat(_.values(level.restrictedGear)) if level.restrictedGear
    originals = _.uniq _.flatten originals
    for original in originals
      thangType = new ThangType()
      thangType.setProjection(thangTypeProject)
      thangType.setURL("/db/thang.type/#{original}/version")
      @supermodel.loadModel(thangType)

  onFundamentalLoaded: ->
    # Load any levels which haven't been denormalized into our campaign.
    return unless @campaign.loaded and @levels.loaded and @achievements.loaded
    @loadMissingLevelsAndRelatedModels()

  loadMissingLevelsAndRelatedModels: ->
    promises = []
    for level in _.values(@campaign.get('levels'))
      continue if model = @levels.findWhere(original: level.original)
      model = new Level({})
      model.setProjection Campaign.denormalizedLevelProperties
      model.setURL("/db/level/#{level.original}/version")
      levelResource = @supermodel.loadModel(model)
      @levels.add levelResource.model
      # Handle SuperModel's caching, and make sure loaded levels save and notice changes properly
      if levelResource.jqxhr
        levelResource.model.once('sync', ->
          @setURL("/db/level/#{@id}")
          @markToRevert()
        )
        promises.push(levelResource.jqxhr)
      achievements = new RelatedAchievementsCollection level.original
      achievements.setProjection achievementProject
      achievementsResource = @supermodel.loadCollection(achievements)
      promises.push(achievementsResource.jqxhr)
      @listenToOnce achievements, 'sync', (achievementsLoaded) ->
        @achievements.add(achievementsLoaded.models)
    return Promise.resolve($.when(promises...))

  onLoaded: ->
    @updateCampaignLevels()
    @campaignView.render()
    super()
    if window.location.hash
      levelSlug = window.location.hash.substring(1)
      levelOriginal = _.find(@campaign.get('levels'), slug: levelSlug).original
      @openCampaignLevelView @supermodel.getModelByOriginal Level, levelOriginal

  updateCampaignLevels: ->
    @toSave.add @campaign if @campaign.hasLocalChanges()
    campaignLevels = $.extend({}, @campaign.get('levels'))
    for level, levelIndex in @levels.models
      levelOriginal = level.get('original')
      campaignLevel = campaignLevels[levelOriginal]
      continue if not campaignLevel
      $.extend campaignLevel, _.pick(level.attributes, Campaign.denormalizedLevelProperties)
      # TODO: better way for it to remember when we intend to not specifically require/restrict gear any more
      delete campaignLevel.requiredGear if not level.attributes.requiredGear
      delete campaignLevel.restrictedGear if not level.attributes.restrictedGear
      campaignLevel.rewards = @formatRewards level
      # Save campaign to level if it's a main 'hero' campaign so HeroVictoryModal knows where to return.
      # (Not if it's a defaulted, typeless campaign like game-dev-hoc or auditions.)
      campaignLevel.campaign = @campaign.get 'slug' if @campaign.get('type') is 'hero'
      # Save campaign index to level if it's a course campaign, since we show linear level order numbers for course levels.
      campaignLevel.campaignIndex = (@levels.models.length - levelIndex - 1) if @campaign.get('type', true) is 'course'
      campaignLevels[levelOriginal] = campaignLevel

    @campaign.set('levels', campaignLevels)

    for level in _.values campaignLevels
      continue if /test/.test @campaign.get('slug')  # Don't overwrite level stuff for testing Campaigns
      model = @levels.findWhere {original: level.original}
      # do not propagate campaignIndex for non-course campaigns
      propsToPropagate = Campaign.denormalizedLevelProperties
      if @campaign.get('type') isnt 'course'
        propsToPropagate = _.without(propsToPropagate, 'campaignIndex')
      for key in propsToPropagate
        model.set key, level[key] if model.get(key) isnt level[key]
      @toSave.add model if model.hasLocalChanges()

  formatRewards: (level) ->
    achievements = @achievements.where related: level.get('original')
    rewards = []
    for achievement in achievements
      for rewardType, rewardArray of achievement.get('rewards')
        for reward in rewardArray
          rewardObject = { achievement: achievement.id }

          if rewardType is 'heroes'
            rewardObject.hero = reward
            thangType = new ThangType({}, {project: thangTypeProject})
            thangType.setURL("/db/thang.type/#{reward}/version")
            @supermodel.loadModel(thangType)

          if rewardType is 'levels'
            rewardObject.level = reward
            if not @levels.findWhere({original: reward})
              level = new Level({}, {project: Campaign.denormalizedLevelProperties})
              level.setURL("/db/level/#{reward}/version")
              @supermodel.loadModel(level)

          if rewardType is 'items'
            rewardObject.item = reward
            thangType = new ThangType({}, {project: thangTypeProject})
            thangType.setURL("/db/thang.type/#{reward}/version")
            @supermodel.loadModel(thangType)

          rewards.push rewardObject
    rewards

  propagateCampaignIndexes: ->
    campaignLevels = $.extend({}, @campaign.get('levels'))
    index = 0
    for levelOriginal, campaignLevel of campaignLevels
      if @campaign.get('type') is 'course'
        level = @levels.findWhere({original: levelOriginal})
        if level and level.get('campaignIndex') isnt index
          level.set('campaignIndex', index)
      campaignLevel.campaignIndex = index
      index += 1
      @campaign.set('levels', campaignLevels)

  onClickPatches: (e) ->
    @patchesView = @insertSubView(new PatchesView(@campaign), @$el.find('.patches-view'))
    @patchesView.load()
    @patchesView.$el.removeClass 'hidden'

  onClickAnalyticsButton: ->
    @openModalView new CampaignAnalyticsModal {}, @campaignHandle, @campaignAnalytics

  onAnalyticsModalClosed: (options) ->
    if options.targetLevelSlug? and @treema.childrenTreemas?.levels?.childrenTreemas?
      for original, level of @treema.childrenTreemas.levels.childrenTreemas
        if level.data?.slug is options.targetLevelSlug
          @openCampaignLevelView @supermodel.getModelByOriginal Level, original
          break

  onClickSaveButton: (e) ->
    return if @openingModal
    @openingModal = true
    @loadMissingLevelsAndRelatedModels().then(=>
      @openingModal = false
      @propagateCampaignIndexes()
      @updateCampaignLevels()
      @toSave.set @toSave.filter (m) -> m.hasLocalChanges()
      @openModalView new SaveCampaignModal({}, @toSave)
    )

  afterRender: ->
    super()
    treemaOptions =
      schema: Campaign.schema
      data: $.extend({}, @campaign.attributes)
      filePath: "db/campaign/#{@campaign.get('_id')}"
      callbacks:
        change: @onTreemaChanged
        select: @onTreemaSelectionChanged
        dblclick: @onTreemaDoubleClicked
        achievementUpdated: @onAchievementUpdated
      nodeClasses:
        levels: LevelsNode
        level: LevelNode
        nextLevel: NextLevelNode 
        campaigns: CampaignsNode
        campaign: CampaignNode
        achievement: AchievementNode
        rewards: RewardsNode
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
    @listenTo @campaignView, 'level-double-clicked', @onCampaignLevelDoubleClicked
    @listenTo @campaign, 'change:i18n', =>
      @campaign.updateI18NCoverage()
      @treema.set('/i18n', @campaign.get('i18n'))
      @treema.set('/i18nCoverage', @campaign.get('i18nCoverage'))

    @insertSubView @campaignView

  onTreemaChanged: (e, nodes) =>
    unless /test/.test @campaign.get('slug')  # Don't overwrite level stuff for testing Campaigns
      for node in nodes
        path = node.getPath()
        if _.string.startsWith path, '/levels/'
          parts = path.split('/')
          original = parts[2]
          level = @supermodel.getModelByOriginal Level, original
          campaignLevel = @treema.get "/levels/#{original}"
          level.set key, campaignLevel[key] for key in Campaign.denormalizedLevelProperties
          @toSave.add level if level.hasLocalChanges()

    @toSave.add @campaign
    @campaign.set key, value for key, value of @treema.data
    @campaignView.setCampaign(@campaign)

  onTreemaSelectionChanged: (e, node) =>
    return unless node[0]?.data?.original?
    elem = @$("div[data-level-original='#{node[0].data.original}']")
    elem.toggle('pulsate')
    setTimeout ()->
      elem.toggle('pulsate')
    , 1000

  onTreemaDoubleClicked: (e, node) =>
    path = node.getPath()
    return unless _.string.startsWith path, '/levels/'
    original = path.split('/')[2]
    @openCampaignLevelView @supermodel.getModelByOriginal Level, original

  onAchievementUpdated: (e, node) =>
    @supermodel.registerModel e.achievement
    @achievements.findWhere({_id: e.achievement.id}).set('rewards', e.achievement.get('rewards'))
    @updateCampaignLevels()  # TODO: only change the rewards for the one we had, don't wipe anything else
    levelOriginal = node.getPath().split('/')[2]
    level = @levels.findWhere original: levelOriginal
    rewardsPath = "/levels/#{levelOriginal}/rewards"
    @treema.set rewardsPath, @formatRewards level
    @campaignView.setCampaign @campaign

  onCampaignLevelMoved: (e) ->
    path = "levels/#{e.levelOriginal}/position"
    @treema.set path, e.position

  onAdjacentCampaignMoved: (e) ->
    path = "adjacentCampaigns/#{e.campaignID}/position"
    @treema.set path, e.position

  onCampaignLevelClicked: (levelOriginal) ->
    return unless levelTreema = @treema.childrenTreemas?.levels?.childrenTreemas?[levelOriginal]
    if key.ctrl or key.command
      url = "/editor/level/#{levelTreema.data.slug}"
      window.open url, '_blank'
    levelTreema.select()
    #levelTreema.open()

  onCampaignLevelDoubleClicked: (levelOriginal) ->
    @openCampaignLevelView @supermodel.getModelByOriginal Level, levelOriginal

  openCampaignLevelView: (level) ->
    @insertSubView campaignLevelView = new CampaignLevelView({}, level)
    @listenToOnce campaignLevelView, 'hidden', => @$el.find('#campaign-view').show()
    @$el.find('#campaign-view').hide()

  onClickLoginButton: ->
    # Do Nothing
    # This is a override method to RootView, so that only CampaignView is listenting to login button click

  onClickSignupButton: ->
    # Do Nothing
    # This is a override method to RootView, so that only CampaignView is listenting to signup button click

class LevelsNode extends TreemaObjectNode
  valueClass: 'treema-levels'
  @levels: {}
  ordered: true

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

      # Sort the results. Prioritize names that start with the search term, then contain the search term.
      lowerPriority = _.clone(mapped)
      lowerTerm = req.term.toLowerCase()
      startsWithTerm = _.filter(lowerPriority, (item) -> _.string.startsWith(item.label.toLowerCase(), lowerTerm))
      _.pull(lowerPriority, startsWithTerm...)
      hasTerm = _.filter(lowerPriority, (item) -> _.string.contains(item.label.toLowerCase(), lowerTerm))
      _.pull(lowerPriority, hasTerm...)
      sorted = _.flatten([startsWithTerm, hasTerm, lowerPriority])
      res(sorted)

class LevelNode extends TreemaObjectNode
  valueClass: 'treema-level'
  buildValueForDisplay: (valEl, data) ->
    name = data.name
    if data.requiresSubscription
      name = "[P] " + name

    status = ''
    el = 'strong'
    if data.adminOnly
      status += " (disabled)"
      el = 'span'
    else if data.adventurer
      status += " (adventurer)"

    completion = ''

    valEl.append $("<a href='/editor/level/#{_.string.slugify(data.name)}' class='spr'>(e)</a>")
    valEl.append $("<#{el}></#{el}>").addClass('treema-shortened').text name
    if status
      valEl.append $('<em class="spl"></em>').text status
    if completion
      valEl.append $('<span class="completion"></span>').text completion

  populateData: ->
    return if @data.name?
    data = _.pick LevelsNode.levels[@keyForParent].attributes, Campaign.denormalizedLevelProperties
    _.extend @data, data

class NextLevelNode extends LevelNode
  populateData: ->
    return if @data.name?
    data = _.pick LevelsNode.levels[@keyForParent].attributes, ['original', 'name', 'slug', 'type']
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
    s.fetch({data: {term:req.term, project: Campaign.denormalizedCampaignProperties}})
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
    # TODO: Need to be able to update i18n links to other campaigns
    data = _.pick CampaignsNode.campaigns[@keyForParent].attributes, Campaign.denormalizedCampaignProperties
    _.extend @data, data

class AchievementNode extends treemaExt.IDReferenceNode
  buildSearchURL: (term) -> "#{@url}?term=#{term}&project=#{achievementProject.join(',')}"

  buildValueForDisplay: (valEl, data) ->
    super valEl, data
    addAchievementEditorLink @, valEl, data

class RewardsNode extends TreemaArrayNode
  buildValueForDisplay: (valEl, data) ->
    super valEl, data
    achievements = window.currentView.achievements.where related: @parent.data.original
    achievements = _.sortBy achievements, (a) -> a.get('rewards')?.levels?.length ? 0
    mainAchievement = achievements[0]
    return unless mainAchievement
    addAchievementEditorLink @, valEl, mainAchievement.id

addAchievementEditorLink = (node, valEl, achievementId) ->
  anchor = $('<a class="spl">(e)</a>')
  anchor.on 'click', (event) ->
    childWindow = window.open("/editor/achievement/#{achievementId}", achievementId, 'width=1040,height=900,left=1600,top=0,location=1,menubar=1,scrollbars=1,status=0,titlebar=1,toolbar=1', true)
    childWindow.achievementSavedCallback = (event) ->
      node.callbacks.achievementUpdated {achievement: event.achievement}, node
    childWindow.focus()
    event.stopPropagation()
  valEl.find('.treema-shortened').append anchor
