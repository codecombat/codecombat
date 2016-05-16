ModalView = require 'views/core/ModalView'
template = require 'templates/play/modal/leaderboard-modal'
LeaderboardTabView = require 'views/play/modal/LeaderboardTabView'
Level = require 'models/Level'
utils = require 'core/utils'

module.exports = class LeaderboardModal extends ModalView
  id: 'leaderboard-modal'
  template: template
  instant: true
  timespans: ['day', 'week', 'all']

  subscriptions: {}

  events:
    'shown.bs.tab #leaderboard-nav a': 'onTabShown'
    'click #close-modal': 'hide'

  constructor: (options) ->
    super options
    @levelSlug = @options.levelSlug
    level = new Level({_id: @levelSlug})
    level.project = ['name', 'i18n', 'scoreType', 'original']
    @level = @supermodel.loadModel(level).model

  getRenderData: (c) ->
    c = super c
    c.submenus = []
    for scoreType in @level.get('scoreTypes') ? []
      for timespan in @timespans
        c.submenus.push scoreType: scoreType, timespan: timespan
    c.levelName = utils.i18n @level.attributes, 'name'
    c

  afterRender: ->
    super()
    return unless @supermodel.finished()
    for scoreType, scoreTypeIndex in @level.get('scoreTypes') ? []
      for timespan, timespanIndex in @timespans
        submenuView = new LeaderboardTabView scoreType: scoreType, timespan: timespan, level: @level
        @insertSubView submenuView, @$el.find "##{scoreType}-#{timespan}-view .leaderboard-tab-view"
        if scoreTypeIndex + timespanIndex is 0
          submenuView.$el.parent().addClass 'active'
          submenuView.onShown?()
    @playSound 'game-menu-open'
    @$el.find('.nano:visible').nanoScroller()

  onTabShown: (e) ->
    @playSound 'game-menu-tab-switch'
    tabChunks = e.target.hash.substring(1).split '-'
    scoreType = tabChunks[0 ... tabChunks.length - 2].join '-'
    timespan = tabChunks[tabChunks.length - 2]
    subview = _.find @subviews, scoreType: scoreType, timespan: timespan
    subview.onShown?()
    otherSubview.onHidden?() for subviewKey, otherSubview of @subviews when otherSubview isnt subview

  onHidden: ->
    super()
    subview.onHidden?() for subviewKey, subview of @subviews
    @playSound 'game-menu-close'
