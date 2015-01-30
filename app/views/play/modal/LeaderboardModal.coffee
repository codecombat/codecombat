ModalView = require 'views/core/ModalView'
template = require 'templates/play/modal/leaderboard-modal'
LeaderboardTabView = require 'views/play/modal/LeaderboardTabView'

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
    @levelOriginal = @options.levelOriginal


  getRenderData: (c) ->
    c = super c
    c.submenus = @timespans
    c.showTab = c.submenus[0]
    c

  afterRender: ->
    super()
    for timespan, index in @timespans
      submenuView = new LeaderboardTabView timespan: timespan, levelOriginal: @levelOriginal
      @insertSubView submenuView, @$el.find "##{timespan}-view .leaderboard-tab-view"
      if index is 0
        submenuView.$el.parent().addClass 'active'
        submenuView.onShown?()
    @playSound 'game-menu-open'
    @$el.find('.nano:visible').nanoScroller()

  onTabShown: (e) ->
    @playSound 'game-menu-tab-switch'
    timespan = e.target.hash.substring(1).replace(/-view/g, '')
    subview = _.find @subviews, timespan: timespan
    subview.onShown?()
    otherSubview.onHidden?() for subviewKey, otherSubview of @subviews when otherSubview isnt subview

  onHidden: ->
    super()
    subview.onHidden?() for subviewKey, subview of @subviews
    @playSound 'game-menu-close'
