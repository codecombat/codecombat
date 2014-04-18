View = require 'views/kinds/CocoView'
template = require 'templates/play/level/level_loading'


module.exports = class LevelLoadingView extends View
  id: "level-loading-view"
  template: template

  subscriptions:
    'level-loader:progress-changed': 'onLevelLoaderProgressChanged'

  afterRender: ->
    @$el.find('.tip.rare').remove() if _.random(1, 10) < 9
    tips = @$el.find('.tip').addClass('to-remove')
    tip = _.sample(tips)
    $(tip).removeClass('to-remove')
    @$el.find('.to-remove').remove()

  onLevelLoaderProgressChanged: (e) ->
    return if @destroyed
    @progress = e.progress
    @progress = 0.01 if @progress < 0.01
    @updateProgressBar()

  updateProgressBar: ->
    @$el.find('.progress-bar').css('width', (100 * @progress) + '%')

  showReady: ->
    ready = $.i18n.t('play_level.loading_ready', defaultValue: 'Ready!')
    @$el.find('#tip-wrapper .tip').addClass('ready').text ready
    Backbone.Mediator.publish 'play-sound', trigger: 'loading_ready', volume: 0.75

  unveil: ->
    _.delay @reallyUnveil, 1000

  reallyUnveil: =>
    return if @destroyed
    @$el.addClass 'unveiled'
    loadingDetails = @$el.find('.loading-details')
    duration = parseFloat loadingDetails.css 'transition-duration'
    loadingDetails.css 'top', -loadingDetails.outerHeight(true)
    @$el.find('.left-wing').css left: '-100%', backgroundPosition: 'right -400px top 0'
    @$el.find('.right-wing').css right: '-100%', backgroundPosition: 'left -400px top 0'
    _.delay @onUnveilEnded, duration * 1000

  onUnveilEnded: =>
    return if @destroyed
    Backbone.Mediator.publish 'level:loading-view-unveiled', view: @
