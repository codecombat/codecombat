View = require 'views/kinds/CocoView'
template = require 'templates/play/level/level_loading'

module.exports = class LevelLoadingView extends View
  id: "level-loading-view"
  template: template

  subscriptions:
    'level-loader:progress-changed': 'onLevelLoaderProgressChanged'

  onLevelLoaderProgressChanged: (e) ->
    @progress = e.progress
    @updateProgressBar()

  updateProgressBar: ->
    #@text.text = "BUILDING" if @progress is 1
    @$el.find('.progress-bar').css('width', (100 * @progress) + '%')

  showReady: ->
    return

  unveil: ->
    _.delay @reallyUnveil, 1000

  reallyUnveil: =>
    return if @destroyed
    loadingDetails = @$el.find('.loading-details')
    duration = parseFloat loadingDetails.css 'transition-duration'
    loadingDetails.css 'top', -loadingDetails.outerHeight(true)
    @$el.find('.left-wing').css left: '-100%', backgroundPosition: 'right -400px top 0'
    @$el.find('.right-wing').css right: '-100%', backgroundPosition: 'left -400px top 0'
    _.delay @onUnveilEnded, duration * 1000

  onUnveilEnded: =>
    return if @destroyed
    Backbone.Mediator.publish 'onLoadingViewUnveiled', view: @

  getRenderData: (c={}) ->
    super c
    c
