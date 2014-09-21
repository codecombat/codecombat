CocoView = require 'views/kinds/CocoView'
template = require 'templates/play/level/level_loading'

module.exports = class LevelLoadingView extends CocoView
  id: 'level-loading-view'
  template: template

  events:
    'mousedown .start-level-button': 'startUnveiling'  # split into two for animation smoothness
    'click .start-level-button': 'onClickStartLevel'

  subscriptions:
    'level:loaded': 'onLevelLoaded'

  afterRender: ->
    @$el.find('.tip.rare').remove() if _.random(1, 10) < 9
    tips = @$el.find('.tip').addClass('to-remove')
    tip = _.sample(tips)
    $(tip).removeClass('to-remove')
    @$el.find('.to-remove').remove()

  onLevelLoaded: (e) ->
    @level = e.level
    goalList = @$el.find('.level-loading-goals').removeClass('secret').find('ul')
    for goalID, goal of @level.get('goals') when not goal.team or goal.team is e.team
      goalList.append $('<li class="list-group-item header-font">' + goal.name + '</li>')
    console.log 'got goals', @level.get('goals'), 'team', e.team

  showReady: ->
    return if @shownReady
    @shownReady = true
    ready = $.i18n.t('play_level.loading_ready', defaultValue: 'Ready!')
    @$el.find('#tip-wrapper .tip').addClass('ready').text ready
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'level_loaded', volume: 0.75  # old: loading_ready
    @$el.find('.start-level-button').removeClass 'secret'

  startUnveiling: (e) ->
    Backbone.Mediator.publish 'level:loading-view-unveiling', {}

  onClickStartLevel: (e) ->
    @unveil()

  unveil: ->
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
