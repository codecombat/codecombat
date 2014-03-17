View = require 'views/kinds/CocoView'
template = require 'templates/play/level/level_loading'


tips = [
  "Tip: you can shift+click a position on the map to insert it into the spell editor."
  "You can toggle play/paused with ctrl+p."
  "Pressing ctrl+[ and ctrl+] rewinds and fast-forwards."
  "CodeCombat is 100% open source!"
  "In the future, even babies will be Archmages."
  "Loading will continue until morale improves."
  "CodeCombat launched its beta in October, 2013."
  "JavaScript is just the beginning."
  "We believe in equal opportunities to learn programming for all species."
]

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
    @$el.find('h2').addClass('ready').text 'Ready!'

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
    c.tip = _.sample tips
    c
