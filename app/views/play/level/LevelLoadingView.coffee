CocoView = require 'views/kinds/CocoView'
template = require 'templates/play/level/level_loading'
utils = require 'lib/utils'

module.exports = class LevelLoadingView extends CocoView
  id: 'level-loading-view'
  template: template

  events:
    'mousedown .start-level-button': 'startUnveiling'  # Split into two for animation smoothness.
    'click .start-level-button': 'onClickStartLevel'

  subscriptions:
    'level:loaded': 'onLevelLoaded'  # If Level loads after level loading view.

  afterRender: ->
    super()
    @$el.find('.tip.rare').remove() if _.random(1, 10) < 9
    tips = @$el.find('.tip').addClass('to-remove')
    tip = _.sample(tips)
    $(tip).removeClass('to-remove')
    @$el.find('.to-remove').remove()
    @onLevelLoaded level: @options.level if @options.level?.get('goals')  # If Level was already loaded.

  afterInsert: ->
    super()
    _.defer =>
      return if @destroyed
      # Make sure that we are as tall now as we will be when the canvas wrapper is resized to the right height.
      canvasAspectRatio = 924 / 589
      eventualCanvasWidth = $('#canvas-wrapper').outerWidth()
      eventualCanvasHeight = Math.max(eventualCanvasWidth / canvasAspectRatio)
      currentCanvasHeight = 589
      @$el.addClass('manually-sized').css('height', @$el.outerHeight() + eventualCanvasHeight - currentCanvasHeight + 2)

  onLevelLoaded: (e) ->
    @level = e.level
    goalContainer = @$el.find('.level-loading-goals')
    goalList = goalContainer.find('ul')
    goalCount = 0
    for goalID, goal of @level.get('goals') when (not goal.team or goal.team is e.team) and not goal.hiddenGoal
      name = utils.i18n goal, 'name'
      goalList.append $('<li class="list-group-item">' + name + '</li>')
      ++goalCount
    if goalCount
      goalContainer.removeClass('secret')
      if goalCount is 1
        goalContainer.find('.panel-heading').text $.i18n.t 'play_level.goal'  # Not plural

  showReady: ->
    return if @shownReady
    @shownReady = true
    _.delay @finishShowingReady, 1500  # Let any blocking JS hog the main thread before we show that we're done.

  finishShowingReady: =>
    return if @destroyed
    if @options.autoUnveil
      @startUnveiling()
      @unveil()
    else
      ready = $.i18n.t('play_level.loading_ready', defaultValue: 'Ready!')
      @$el.find('#tip-wrapper .tip').addClass('ready').text ready
      Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'level_loaded', volume: 0.75  # old: loading_ready
      @$el.find('.progress').addClass 'active progress-striped'
      @$el.find('.start-level-button').removeClass 'secret'
      @$el.removeClass('manually-sized').css('height', '100%')

  startUnveiling: (e) ->
    Backbone.Mediator.publish 'level:loading-view-unveiling', {}
    _.delay @onClickStartLevel, 1000  # If they never mouse-up for the click (or a modal shows up and interrupts the click), do it anyway.

  onClickStartLevel: (e) =>
    return if @destroyed
    @unveil()

  unveil: ->
    return if @$el.hasClass 'unveiled'
    @$el.addClass 'unveiled'
    loadingDetails = @$el.find('.loading-details')
    duration = parseFloat loadingDetails.css 'transition-duration'
    loadingDetails.css 'top', -loadingDetails.outerHeight(true)
    @$el.find('.left-wing').css left: '-100%', backgroundPosition: 'right -400px top 0'
    @$el.find('.right-wing').css right: '-100%', backgroundPosition: 'left -400px top 0'
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'loading-view-unveil', volume: 0.5
    _.delay @onUnveilEnded, duration * 1000

  onUnveilEnded: =>
    return if @destroyed
    Backbone.Mediator.publish 'level:loading-view-unveiled', view: @
