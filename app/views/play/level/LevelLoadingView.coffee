CocoView = require 'views/core/CocoView'
template = require 'templates/play/level/level_loading'
utils = require 'core/utils'
SubscribeModal = require 'views/core/SubscribeModal'

module.exports = class LevelLoadingView extends CocoView
  id: 'level-loading-view'
  template: template

  events:
    'mousedown .start-level-button': 'startUnveiling'  # Split into two for animation smoothness.
    'click .start-level-button': 'onClickStartLevel'
    'click .start-subscription-button': 'onClickStartSubscription'

  subscriptions:
    'level:loaded': 'onLevelLoaded'  # If Level loads after level loading view.
    'level:subscription-required': 'onSubscriptionRequired'  # If they'd need a subscription to start playing.
    'subscribe-modal:subscribed': 'onSubscribed'

  shortcuts:
    'enter': 'onEnterPressed'

  afterRender: ->
    super()
    @$el.find('.tip.rare').remove() if _.random(1, 10) < 9
    tips = @$el.find('.tip').addClass('to-remove')
    tip = _.sample(tips)
    $(tip).removeClass('to-remove').addClass('secret')
    @$el.find('.to-remove').remove()
    @onLevelLoaded level: @options.level if @options.level?.get('goals')  # If Level was already loaded.

  afterInsert: ->
    super()
    _.defer =>
      return if @destroyed
      # Make sure that we are as tall now as we will be when the canvas wrapper is resized to the right height.
      currentCanvasHeight = 589
      canvasAspectRatio = 924 / 589
      eventualCanvasWidth = $('#canvas-wrapper').outerWidth()
      eventualCanvasHeight = eventualCanvasWidth / canvasAspectRatio
      newHeight = Math.max 769, @$el.outerHeight() + eventualCanvasHeight - currentCanvasHeight + 2
      @$el.addClass('manually-sized').css('height', newHeight)

  onLevelLoaded: (e) ->
    @level = e.level
    goalContainer = @$el.find('.level-loading-goals')
    goalList = goalContainer.find('ul')
    goalCount = 0
    for goalID, goal of @level.get('goals') when (not goal.team or goal.team is (e.team or 'humans')) and not goal.hiddenGoal
      name = utils.i18n goal, 'name'
      goalList.append $('<li>' + name + '</li>')
      ++goalCount
    if goalCount
      goalContainer.removeClass('secret')
      if goalCount is 1
        goalContainer.find('.panel-heading').text $.i18n.t 'play_level.goal'  # Not plural
    tip = @$el.find('.tip')
    if @level.get('loadingTip')
      loadingTip = utils.i18n @level.attributes, 'loadingTip'
      tip.text(loadingTip)
    tip.removeClass('secret')

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
      Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'level_loaded', volume: 0.75  # old: loading_ready
      @$el.find('.progress').hide()
      @$el.find('.start-level-button').show()

  startUnveiling: (e) ->
    @playSound 'menu-button-click'
    Backbone.Mediator.publish 'level:loading-view-unveiling', {}
    _.delay @onClickStartLevel, 1000  # If they never mouse-up for the click (or a modal shows up and interrupts the click), do it anyway.

  onClickStartLevel: (e) =>
    return if @destroyed
    @unveil()

  onEnterPressed: (e) ->
    return unless @shownReady and not @$el.hasClass 'unveiled'
    @startUnveiling()
    @onClickStartLevel()

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
    $('#level-footer-background').detach().appendTo('#page-container').slideDown(duration * 1000)

  onUnveilEnded: =>
    return if @destroyed
    Backbone.Mediator.publish 'level:loading-view-unveiled', view: @

  onSubscriptionRequired: (e) ->
    @$el.find('.level-loading-goals, .tip, .load-progress').hide()
    @$el.find('.subscription-required').show()

  onClickStartSubscription: (e) ->
    @openModalView new SubscribeModal()
    window.tracker?.trackEvent 'Show subscription modal', category: 'Subscription', label: 'level loading', level: @level?.get('slug') or @options.level?.get('slug')

  onSubscribed: ->
    document.location.reload()
