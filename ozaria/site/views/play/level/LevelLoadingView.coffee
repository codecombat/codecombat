require('ozaria/site/styles/play/level/level-loading-view.sass')
CocoView = require 'views/core/CocoView'
template = require 'ozaria/site/templates/play/level/level-loading-view'
ace = require('lib/aceContainer')
utils = require 'core/utils'
aceUtils = require 'core/aceUtils'
SubscribeModal = require 'views/core/SubscribeModal'
LevelGoals = require('./LevelGoals').default
store = require 'core/store'

module.exports = class LevelLoadingView extends CocoView
  id: 'level-loading-view'
  template: template

  events:
    'click .start-subscription-button': 'onClickStartSubscription'

  subscriptions:
    'level:loaded': 'onLevelLoaded'  # If Level loads after level loading view.
    'level:session-loaded': 'onSessionLoaded'
    'level:subscription-required': 'onSubscriptionRequired'  # If they'd need a subscription.
    'level:course-membership-required': 'onCourseMembershipRequired'  # If they need to be added to a course.
    'level:license-required': 'onLicenseRequired' # If they need a license.
    'subscribe-modal:subscribed': 'onSubscribed'

  afterRender: ->
    super()
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
    @prepareGoals e
    @prepareTip()

  onSessionLoaded: (e) ->
    return if @session
    @session = e.session if e.session.get('creator') is me.id

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

  showReady: ->
    return if @shownReady
    @shownReady = true
    _.delay @finishShowingReady, 100  # Let any blocking JS hog the main thread before we show that we're done.

  finishShowingReady: =>
    return if @destroyed
    @playSound 'level_loaded', 0.75  # old: loading_ready
    @unveil()

  unveil: () ->
    return if @destroyed
    @$loadingDetails = @$el.find('#loading-details')
    duration = parseFloat(@$loadingDetails.css 'transition-duration') * 1000
    unless @$el.hasClass 'unveiled'
      @$el.addClass 'unveiled'
      @unveilWings duration
    @unveilLoadingFull()
    _.delay @onUnveilEnded, duration

  unveilLoadingFull: ->
    # Get rid of the loading details screen entirely--the level is totally ready.
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

  resize: ->
    maxHeight = $('#page-container').outerHeight(true)
    minHeight = $('#code-area').outerHeight(true)
    minHeight -= 20
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
    $('#level-footer-background').detach().appendTo('#page-container').slideDown(duration) unless @level?.isType('web-dev')

  onUnveilEnded: =>
    return if @destroyed
    Backbone.Mediator.publish 'level:loading-view-unveiled', view: @

  onWindowResize: (e) =>
    return if @destroyed
    @$loadingDetails.css transition: 'none'
    @resize()

  onSubscriptionRequired: (e) ->
    @$el.find('.level-loading-goals, .tip, .progress-or-start-container').hide()
    @$el.find('.subscription-required').show()

  onCourseMembershipRequired: (e) ->
    @$el.find('.level-loading-goals, .tip, .progress-or-start-container').hide()
    @$el.find('.course-membership-required').show()

  onLicenseRequired: (e) ->
    @$el.find('.level-loading-goals, .tip, .progress-or-start-container').hide()
    @$el.find('.license-required').show()

  onLoadError: (resource) ->
    @$el.find('.level-loading-goals, .tip, .progress-or-start-container').hide()
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
