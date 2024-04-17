require('app/styles/play/level/level-loading-view.sass')
CocoView = require 'views/core/CocoView'
template = require 'app/templates/play/level/level-loading-view'
ace = require('lib/aceContainer')
utils = require 'core/utils'
aceUtils = require 'core/aceUtils'
aetherUtils = require 'lib/aether_utils'
SubscribeModal = require 'views/core/SubscribeModal'
LevelGoals = require('./LevelGoals').default
store = require 'core/store'

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
    'level:subscription-required': 'onSubscriptionRequired'  # If they'd need a subscription.
    'level:course-membership-required': 'onCourseMembershipRequired'  # If they need to be added to a course.
    'level:license-required': 'onLicenseRequired' # If they need a license.
    'level:locked': 'onLevelLocked'
    'subscribe-modal:subscribed': 'onSubscribed'

  shortcuts:
    'enter': 'onEnterPressed'

  initialize: (options={}) ->
    @utils = utils
    @loadingWingClass = _.sample(['alejandro', 'anya', 'chess', 'naria', 'okar'])

  afterRender: ->
    super()
    return if utils.isOzaria
    unless @level?.get('loadingTip')
      @$el.find('.tip.rare').remove() if _.random(1, 10) < 9
      tips = @$el.find('.tip').addClass('to-remove')
      tip = _.sample(tips)
      $(tip).removeClass('to-remove').addClass('secret')
      @$el.find('.to-remove').remove()
    @onLevelLoaded level: @options.level if @options.level?.get('goals')  # If Level was already loaded.
    @configureACEEditors()

  configureACEEditors: ->
    codeLanguage = @session?.get('codeLanguage') or me.get('aceConfig')?.language or 'python'
    oldEditor.destroy() for oldEditor in @aceEditors ? []
    @aceEditors = []
    aceEditors = @aceEditors
    @$el.find('pre:has(code[class*="lang-"])').each ->
      aceEditor = aceUtils.initializeACE @, codeLanguage
      aceEditors.push aceEditor

  afterInsert: ->
    super()

  onLevelLoaded: (e) ->
    return if @level
    @level = e.level
    @$el.toggleClass 'codecombat-junior', @level.get('product', true) is 'codecombat-junior'
    @$el.toggleClass 'codecombat', @level.get('product', true) is 'codecombat'
    if utils.isCodeCombat and @level.get('product', true) is 'codecombat'
      @prepareGoals e
      @prepareTip()
      @prepareIntro()
    else if @level.get('product', true) is 'codecombat-junior'
      @prepareLevelName()

  onSessionLoaded: (e) ->
    return if @session
    @session = e.session if e.session.get('creator') is me.id

  prepareLevelName: ->
    name = utils.i18n(@level.attributes, 'displayName') or utils.i18n(@level.attributes, 'name')
    @$el.find('.level-name').text(name).show()

  prepareGoals: ->
    @levelGoalsComponent = new LevelGoals({
      el: @$('.list-unstyled')[0],
      store,
      propsData: { showStatus: false }
    })
    @levelGoalsComponent.goals = @level.get('goals')
    goalContainer = @$el.find('.level-loading-goals')
    @buttonTranslationKey = 'play_level.loading_start'
    if @level.get('assessment') is 'cumulative'
      @buttonTranslationKey = 'play_level.loading_start_combo'
    else if @level.get('assessment')
      @buttonTranslationKey = 'play_level.loading_start_concept'
    @$('.start-level-button').text($.i18n.t(@buttonTranslationKey))

    Vue.nextTick(=>
      # TODO: move goals to vuex where everyone can check together which goals are visible.
      # Use that instead of looking into the Vue result
      numGoals = goalContainer.find('li').length
      if numGoals
        goalContainer.removeClass('secret')
        if @level.get('assessment') is 'cumulative'
          if numGoals > 1
            @goalHeaderTranslationKey = 'play_level.combo_challenge_goals'
          else
            @goalHeaderTranslationKey = 'play_level.combo_challenge_goal'
        else if @level.get('assessment')
          if numGoals > 1
            @goalHeaderTranslationKey = 'play_level.concept_challenge_goals'
          else
            @goalHeaderTranslationKey = 'play_level.concept_challenge_goal'
        else
          if numGoals > 1
            @goalHeaderTranslationKey = 'play_level.goals'
          else
            @goalHeaderTranslationKey = 'play_level.goal'
        goalContainer.find('.goals-title').text $.i18n.t @goalHeaderTranslationKey
    )

  prepareTip: ->
    tip = @$el.find('.tip')
    if @level.get('loadingTip')
      loadingTip = utils.i18n @level.attributes, 'loadingTip'
      loadingTip = marked(loadingTip)
      tip.html(loadingTip).removeAttr('data-i18n')
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
    if utils.isCodeCombat
      _.delay @finishShowingReady, 100  # Let any blocking JS hog the main thread before we show that we're done.
    else
      @unveilPreviewTime = new Date().getTime()
      _.delay @startUnveiling, 100  # Let any blocking JS hog the main thread before we show that we're done.

  finishShowingReady: =>
    return if @destroyed
    showIntro = utils.getQueryVariable('intro')
    if showIntro?
      autoUnveil = not showIntro
    else
      autoUnveil = @options.autoUnveil or @session?.get('state').complete or @level.get('product', true) is 'codecombat-junior'
    if autoUnveil
      @startUnveiling()
      @unveil true
    else
      @playSound 'level_loaded', 0.75  # old: loading_ready
      @$el.find('.progress').hide()
      @$el.find('.start-level-button').show()
      @unveil false

  startUnveiling: (e) ->
    # todo: this file, coco and ozar do similar things with different steps, should be refactored
    if utils.isCodeCombat
      @playSound 'menu-button-click'
      @unveiling = true
      Backbone.Mediator.publish 'level:loading-view-unveiling', {}
      _.delay @onClickStartLevel, 1000  # If they never mouse-up for the click (or a modal shows up and interrupts the click), do it anyway.
    else
      levelSlug = @level?.get('slug') or @options?.level?.get('slug')
      timespent = (new Date().getTime() - @unveilPreviewTime) / 1000
      window.tracker?.trackEvent 'Finish Viewing Intro', {
        category: 'Play Level'
        label: 'level loading'
        level: levelSlug
        levelID: levelSlug
        timespent # This is no longer a very useful metric as it now happens right away.
      }
      details = @$('#loading-details')?[0]
      unless details?.style?.display == 'none'
        details?.style?.display = "none"
      Backbone.Mediator.publish 'level:loading-view-unveiled', view: @

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
    if @unveilPreviewTime
      levelSlug = @level?.get('slug') or @options.level?.get('slug')
      timespent = (new Date().getTime() - @unveilPreviewTime) / 1000
      window.tracker?.trackEvent 'Finish Viewing Intro', {
        category: 'Play Level'
        label: 'level loading'
        level: levelSlug
        levelID: levelSlug
        timespent
      }

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
    @unveilPreviewTime = new Date().getTime()

  resize: ->
    goalsHeight = @$el.find('.level-loading-goals').outerHeight(true) or 0
    introDocHeight = @$el.find('.intro-doc-content').outerHeight(true) or 100
    maxHeight = Math.min $('#level-view').outerHeight(true), goalsHeight + introDocHeight + 100 + 0.11 * $(window).innerHeight() + 40
    maxHeight = Math.max maxHeight, 0.5 * $(window).innerHeight()
    minHeight = $('#code-area').outerHeight(true)
    if $('#code-area').offset().top > 100
      # Code area is on the bottom; be just as tall as the game area instead
      minHeight = $('#canvas-wrapper').outerHeight(true) + $('#control-bar-view').outerHeight(true)
    minHeight -= 10
    minHeight = Math.min minHeight, maxHeight
    @$el.css height: '100%'
    @$loadingDetails.css minHeight: minHeight, maxHeight: maxHeight
    if @intro
      $intro = @$el.find('.intro-doc')
      $intro.css height: minHeight - $intro.offset().top - @$el.find('.progress-or-start-container').outerHeight() - 30 - 20
      _.defer -> $intro.find('.nano').nanoScroller alwaysVisible: true

  unveilWings: (duration) ->
    @playSound 'loading-view-unveil', 0.5
    @$el.find('.left-wing').css left: '-100%', backgroundPosition: 'right -400px top 0'
    @$el.find('.right-wing').css right: '-100%', backgroundPosition: 'left -400px top 0'
    $('#level-footer-background').detach().appendTo('#page-container').slideDown(duration) unless @level?.isType('web-dev')

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
      language = @session?.get('codeLanguage')
      html = marked aetherUtils.filterMarkdownCodeLanguages(utils.i18n(@intro, 'body'), language)
    @$el.find('.intro-doc').removeClass('hidden').find('.intro-doc-content').html html
    @resize()
    @configureACEEditors()

  onUnveilEnded: =>
    return if @destroyed
    Backbone.Mediator.publish 'level:loading-view-unveiled', view: @

  onWindowResize: (e) =>
    return if @destroyed
    @$loadingDetails.css transition: 'none'
    @resize()

  onSubscriptionRequired: (e) ->
    return if utils.isOzaria
    @$el.find('.level-loading-goals, .tip, .progress-or-start-container').hide()
    @$el.find('.subscription-required').show()

  onCourseMembershipRequired: (e) ->
    @$el.find('.level-loading-goals, .tip, .progress-or-start-container').hide()
    @$el.find('.course-membership-required').show()

  onLicenseRequired: (e) ->
    @$el.find('.level-loading-goals, .tip, .progress-or-start-container').hide()
    @$el.find('.license-required').show()

  onLevelLocked: (e) ->
    @$el.find('.level-loading-goals, .tip, .progress-or-start-container').hide()
    @$el.find('.level-locked').show()    

  onLoadError: (resource) ->
    startCase = (str) -> str.charAt(0).toUpperCase() + str.slice(1)
    @$el.find('.level-loading-goals, .tip, .progress-or-start-container').hide()
    if resource.resource.jqxhr.status is 404
      @$el.find('.resource-not-found>span').text($.i18n.t('loading_error.resource_not_found', {resource: startCase(resource.resource.name)}))
      @$el.find('.resource-not-found').show()
    else
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
    silentStore = { commit: _.noop, dispatch: _.noop }
    @levelGoalsComponent?.$destroy()
    @levelGoalsComponent?.$store = silentStore
    super()
