require('app/styles/play/level/level-loading-view.sass')
CocoView = require 'views/core/CocoView'
template = require 'app/templates/play/level/level-loading-view'

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
    @unveilPreviewTime = new Date().getTime()
    _.delay @startUnveiling, 100  # Let any blocking JS hog the main thread before we show that we're done.

  startUnveiling: (e) ->
    return if @destroyed
    Backbone.Mediator.publish 'level:loading-view-unveiling', {}
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

  resize: ->
    maxHeight = $('#page-container').outerHeight(true)
    minHeight = $('#code-area').outerHeight(true)
    minHeight -= 20
    @$el.css height: maxHeight
    @$loadingDetails.css minHeight: minHeight, maxHeight: maxHeight

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
    startCase = (str) -> str.charAt(0).toUpperCase() + str.slice(1)
    @$el.find('.progress-or-start-container').hide()
    if resource.resource.jqxhr.status is 404
      @$el.find('.resource-not-found>span').text($.i18n.t('loading_error.resource_not_found', {resource: startCase(resource.resource.name)}))
      @$el.find('.resource-not-found').show()
    else
      @$el.find('.could-not-load').show()

  destroy: ->
    $(window).off 'resize', @onWindowResize
    super()
