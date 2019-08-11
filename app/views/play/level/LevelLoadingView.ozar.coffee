require('app/styles/play/level/level-loading-view.sass')
CocoView = require 'views/core/CocoView'
template = require 'templates/play/level/level-loading-view'

module.exports = class LevelLoadingView extends CocoView
  id: 'level-loading-view'
  template: template

  subscriptions:
    'level:loaded': 'onLevelLoaded'  # If Level loads after level loading view.
    'level:session-loaded': 'onSessionLoaded'
    'level:course-membership-required': 'onCourseMembershipRequired'  # If they need to be added to a course.
    'level:license-required': 'onLicenseRequired' # If they need a license.

  onLevelLoaded: (e) ->
    return if @level
    @level = e.level

  onSessionLoaded: (e) ->
    return if @session
    @session = e.session if e.session.get('creator') is me.id

  showReady: ->
    return if @shownReady
    @shownReady = true
    _.delay @finishShowingReady, 100  # Let any blocking JS hog the main thread before we show that we're done.

  finishShowingReady: =>
    return if @destroyed
    autoUnveil = @options.autoUnveil or @session?.get('state').complete
    if autoUnveil
      @startUnveiling()
      @unveil true
    else
      @$el.find('.progress').hide()
      @unveil false

  startUnveiling: (e) ->
    @unveiling = true
    Backbone.Mediator.publish 'level:loading-view-unveiling', {}
    _.delay =>
      @unveil true
    , 1000

  unveil: (full) ->
    return if @destroyed or @unveiled
    @unveiled = full
    @$loadingDetails = @$el.find('#loading-details')
    duration = parseFloat(@$loadingDetails.css 'transition-duration') * 1000
    if full
      @unveilLoadingFull()
      _.delay @onUnveilEnded, duration

  unveilLoadingFull: ->
    # Get rid of the loading details screen entirely--the level is totally ready.
    unless @unveiling
      Backbone.Mediator.publish 'level:loading-view-unveiling', {}
      @unveiling = true
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

  onUnveilEnded: =>
    return if @destroyed
    details = @$('#loading-details')?[0]
    unless details?.style?.display == 'none'
      details?.style?.display = "none"
    Backbone.Mediator.publish 'level:loading-view-unveiled', view: @

  onWindowResize: (e) =>
    return if @destroyed
    @$loadingDetails.css transition: 'none'
    @resize()

  onCourseMembershipRequired: (e) ->
    @$el.find('.progress-or-start-container').hide()
    @$el.find('.course-membership-required').show()

  onLicenseRequired: (e) ->
    @$el.find('.progress-or-start-container').hide()
    @$el.find('.license-required').show()

  onLoadError: (resource) ->
    @$el.find('.progress-or-start-container').hide()
    @$el.find('.could-not-load').show()

  destroy: ->
    $(window).off 'resize', @onWindowResize
    super()
