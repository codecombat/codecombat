View = require 'views/kinds/CocoView'
template = require 'templates/play/level/level_loading'


module.exports = class LevelLoadingView extends View
  id: "level-loading-view"
  template: template

  onLoaded: ->
  afterRender: ->
    @$el.find('.tip.rare').remove() if _.random(1, 10) < 9
    tips = @$el.find('.tip').addClass('to-remove')
    tip = _.sample(tips)
    $(tip).removeClass('to-remove')
    @$el.find('.to-remove').remove()

  showReady: ->
    ready = $.i18n.t('play_level.loading_ready', defaultValue: 'Ready!')
    @$el.find('#tip-wrapper .tip').addClass('ready').text ready
    Backbone.Mediator.publish 'play-sound', trigger: 'level_loaded', volume: 0.75  # old: loading_ready

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
