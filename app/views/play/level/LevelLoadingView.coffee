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
    'level:session-loaded': 'onSessionLoaded'
    'level:subscription-required': 'onSubscriptionRequired'  # If they'd need a subscription to start playing.
    'level:course-membership-required': 'onCourseMembershipRequired'  # If they'd need a subscription to start playing.
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
    return if @level
    @level = e.level
    @prepareGoals e
    @prepareTip()
    @prepareIntro()

  onSessionLoaded: (e) ->
    return if @session
    @session = e.session if e.session.get('creator') is me.id

  prepareGoals: (e) ->
    goalContainer = @$el.find('.level-loading-goals')
    goalList = goalContainer.find('ul')
    goalCount = 0
    for goalID, goal of @level.get('goals') when (not goal.team or goal.team is (e.team or 'humans')) and not goal.hiddenGoal
      continue if goal.optional and @level.get('type', true) is 'course'
      name = utils.i18n goal, 'name'
      goalList.append $('<li>' + name + '</li>')
      ++goalCount
    if goalCount
      goalContainer.removeClass('secret')
      if goalCount is 1
        goalContainer.find('.panel-heading').text $.i18n.t 'play_level.goal'  # Not plural

  prepareTip: ->
    tip = @$el.find('.tip')
    if @level.get('loadingTip')
      loadingTip = utils.i18n @level.attributes, 'loadingTip'
      tip.text(loadingTip)
    tip.removeClass('secret')

  prepareIntro: ->
    @docs = @level.get('documentation') ? {}
    specific = @docs.specificArticles or []
    @intro = _.find specific, name: 'Intro'
    if window.serverConfig.picoCTF
      @intro ?= body: ''

  showReady: ->
    return if @shownReady
    @shownReady = true
    _.delay @finishShowingReady, 100  # Let any blocking JS hog the main thread before we show that we're done.

  finishShowingReady: =>
    return if @destroyed
    showIntro = @getQueryVariable('intro')
    autoUnveil = not showIntro and (@options.autoUnveil or @session?.get('state').complete)
    if autoUnveil
      @startUnveiling()
      @unveil true
    else
      @playSound 'level_loaded', 0.75  # old: loading_ready
      @$el.find('.progress').hide()
      @$el.find('.start-level-button').show()
      @unveil false

  startUnveiling: (e) ->
    @playSound 'menu-button-click'
    @unveiling = true
    Backbone.Mediator.publish 'level:loading-view-unveiling', {}
    _.delay @onClickStartLevel, 1000  # If they never mouse-up for the click (or a modal shows up and interrupts the click), do it anyway.

  onClickStartLevel: (e) =>
    return if @destroyed
    @unveil true

  onEnterPressed: (e) ->
    return unless @shownReady and not @unveiled
    @startUnveiling()
    @onClickStartLevel()

  unveil: (full) ->
    return if @destroyed or @unveiled
    @unveiled = full
    @$loadingDetails = @$el.find('#loading-details')
    duration = parseFloat(@$loadingDetails.css 'transition-duration') * 1000
    unless @$el.hasClass 'unveiled'
      @$el.addClass 'unveiled'
      @unveilWings duration
    if full
      @unveilLoadingFull()
      _.delay @onUnveilEnded, duration
    else
      @unveilLoadingPreview duration

  unveilLoadingFull: ->
    # Get rid of the loading details screen entirely--the level is totally ready.
    unless @unveiling
      Backbone.Mediator.publish 'level:loading-view-unveiling', {}
      @unveiling = true
    if @$el.hasClass 'preview-screen'
      @$loadingDetails.css 'right', -@$loadingDetails.outerWidth(true)
    else
      @$loadingDetails.css 'top', -@$loadingDetails.outerHeight(true)
    @$el.removeClass 'preview-screen'
    $('#canvas-wrapper').removeClass 'preview-overlay'

  unveilLoadingPreview: (duration) ->
    # Move the loading details screen over the code editor to preview the level.
    return if @$el.hasClass 'preview-screen'
    $('#canvas-wrapper').addClass 'preview-overlay'
    @$el.addClass('preview-screen')
    @$loadingDetails.addClass('preview')
    @resize()
    @onWindowResize = _.debounce @onWindowResize, 700  # Wait a bit for other views to resize before we resize
    $(window).on 'resize', @onWindowResize
    if @intro
      @$el.find('.progress-or-start-container').addClass('intro-footer')
      @$el.find('#tip-wrapper').remove()
      _.delay @unveilIntro, duration

  resize: ->
    maxHeight = $('#page-container').outerHeight(true)
    minHeight = $('#code-area').outerHeight(true)
    @$el.css height: maxHeight
    @$loadingDetails.css minHeight: minHeight, maxHeight: maxHeight
    if @intro
      $intro = @$el.find('.intro-doc')
      $intro.css height: minHeight - $intro.offset().top - @$el.find('.progress-or-start-container').outerHeight() - 30 - 20
      _.defer -> $intro.find('.nano').nanoScroller alwaysVisible: true

  unveilWings: (duration) ->
    @playSound 'loading-view-unveil', 0.5
    @$el.find('.left-wing').css left: '-100%', backgroundPosition: 'right -400px top 0'
    @$el.find('.right-wing').css right: '-100%', backgroundPosition: 'left -400px top 0'
    $('#level-footer-background').detach().appendTo('#page-container').slideDown(duration)

  unveilIntro: =>
    return if @destroyed or not @intro or @unveiled
    if window.serverConfig.picoCTF and problem = @level.picoCTFProblem
      html = marked """
        ### #{problem.name}

        #{@intro.body}

        #{problem.description}

        #{problem.category} - #{problem.score} points
      """, sanitize: false
    else
      html = marked utils.filterMarkdownCodeLanguages(utils.i18n(@intro, 'body'))
    @$el.find('.intro-doc').removeClass('hidden').find('.intro-doc-content').html html
    @resize()

  onUnveilEnded: =>
    return if @destroyed
    Backbone.Mediator.publish 'level:loading-view-unveiled', view: @

  onWindowResize: (e) =>
    return if @destroyed
    @$loadingDetails.css transition: 'none'
    @resize()

  onSubscriptionRequired: (e) ->
    @$el.find('.level-loading-goals, .tip, .load-progress').hide()
    @$el.find('.subscription-required').show()

  onCourseMembershipRequired: (e) ->
    @$el.find('.level-loading-goals, .tip, .load-progress').hide()
    @$el.find('.course-membership-required').show()

  onLoadError: (resource) ->
    @$el.find('.level-loading-goals, .tip, .load-progress').hide()
    @$el.find('.could-not-load').show()

  onClickStartSubscription: (e) ->
    @openModalView new SubscribeModal()
    levelSlug = @level?.get('slug') or @options.level?.get('slug')
    # TODO: Added levelID on 2/9/16. Remove level property and associated AnalyticsLogEvent 'properties.level' index later.
    window.tracker?.trackEvent 'Show subscription modal', category: 'Subscription', label: 'level loading', level: levelSlug, levelID: levelSlug

  onSubscribed: ->
    document.location.reload()

  destroy: ->
    $(window).off 'resize', @onWindowResize
    super()
