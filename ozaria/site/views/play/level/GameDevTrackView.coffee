require('ozaria/site/styles/play/level/game_dev_track_view.sass')
CocoView = require 'views/core/CocoView'
template = require 'templates/play/level/game_dev_track_view'
#teamTemplate = require 'templates/play/level/team_gold'

module.exports = class GameDevTrackView extends CocoView
  id: 'game-dev-track-view'
  template: template

  subscriptions:
    'surface:frame-changed': 'onFrameChanged'
    'playback:real-time-playback-started': 'onRealTimePlaybackStarted'
    'playback:real-time-playback-ended': 'onRealTimePlaybackEnded'

  constructor: (options) ->
    super options
    @listings = {}

  onFrameChanged: (e) ->
    @listings = {}
    # Can be set by a user via `ui.setText("scoreLabel", "overrideLabel")`
    overrideLabel = e.world.uiText?.scoreLabel
    if e.world.synchronous
      for thang in e.world.thangs
        if thang.id is 'Hero Placeholder'
          hero = thang
        if trackedProperties = thang.uiTrackedProperties
          for name in trackedProperties
            @listings[overrideLabel ? name] = thang[name]
      if hero and hero.objTrackedProperties
        for name in hero.objTrackedProperties
          @listings[overrideLabel ? name] = hero['__' + name]
    else
      thangStateMap = e.world.frames[e.frame]?.thangStateMap
      for key, thangState of thangStateMap
        continue unless thangState.trackedPropertyKeys
        trackedPropNamesIndex = thangState.trackedPropertyKeys.indexOf 'uiTrackedProperties'
        unless trackedPropNamesIndex is -1
          trackedPropNames = thangState.props[trackedPropNamesIndex]
          if trackedPropNames
            for name in trackedPropNames
              propIndex = thangState.trackedPropertyKeys.indexOf name
              continue if propIndex is -1
              @listings[overrideLabel ? name] = thangState.props[propIndex]
        continue unless key is 'Hero Placeholder'
        trackedObjNamesIndex = thangState.trackedPropertyKeys.indexOf 'objTrackedProperties'
        continue if trackedObjNamesIndex is -1
        trackedObjNames = thangState.props[trackedObjNamesIndex]
        for name in trackedObjNames
          propIndex = thangState.trackedPropertyKeys.indexOf('__' + name)
          continue if propIndex is -1
          @listings[overrideLabel ? name] = thangState.props[propIndex]
    unless _.isEqual(@listings, {})
      @$el.show()
      @renderSelectors('#listings')
    else
      @$el.hide()

  onRealTimePlaybackStarted: (e) ->
    @$el.addClass('playback-float-right')

  onRealTimePlaybackEnded: (e) ->
    @$el.removeClass('playback-float-right')

  titleize: (name) ->
    return _.string.titleize(_.string.humanize(name))

  beautify: (name, val) ->
    if typeof val is 'object' and val.x? and val.y? and val.z?
      return "x: #{Math.round(val.x)}\ny: #{Math.round(val.y)}"
    if typeof val is 'number'
      round = Math.round(val)
      return round
    return val ? ''
