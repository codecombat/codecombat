CocoClass = require 'core/CocoClass'
AudioPlayer = require 'lib/AudioPlayer'
{me} = require 'core/auth'
createjs = require 'lib/createjs-parts'

CROSSFADE_LENGTH = 1500
MUSIC_VOLUME = 0.6

module.exports = class MusicPlayer extends CocoClass
  currentMusic: null
  standingBy: null

  subscriptions:
    'music-player:play-music': 'onPlayMusic'
    'audio-player:loaded': 'onAudioLoaded'
    'playback:real-time-playback-started': 'onRealTimePlaybackStarted'
    'playback:real-time-playback-ended': 'onRealTimePlaybackEnded'
    'playback:cinematic-playback-started': 'onRealTimePlaybackStarted'  # Handle cinematic the same as real-time
    'playback:cinematic-playback-ended': 'onRealTimePlaybackEnded'
    'music-player:enter-menu': 'onEnterMenu'
    'music-player:exit-menu': 'onExitMenu'
    'level:set-volume': 'onSetVolume'

  constructor: ->
    super arguments...
    me.on 'change:music', @onMusicSettingChanged, @

  onAudioLoaded: (e) ->
    @onPlayMusic(@standingBy) if @standingBy

  onPlayMusic: (e) ->
    return if application.isIPadApp  # Hard to measure, but just guessing this will save memory.
    unless me.get 'volume'
      @lastMusicEventIgnoredWhileMuted = e
      return
    src = e.file
    src = "/file#{src}#{AudioPlayer.ext}" unless /^http/.test(src)
    if (not e.file) or src is @currentMusic?.src
      if e.play then @restartCurrentMusic() else @fadeOutCurrentMusic()
      return

    media = AudioPlayer.getStatus(src)
    if not media?.loaded
      AudioPlayer.preloadSound(src)
      @standingBy = e
      return

    delay = e.delay ? 0
    @standingBy = null
    @fadeOutCurrentMusic()
    @startNewMusic(src, delay) if e.play

  restartCurrentMusic: ->
    return unless @currentMusic
    @currentMusic.play {interrupt: 'none', delay: 0, offset: 0, loop: -1, volume: 0.3}
    @updateMusicVolume()

  fadeOutCurrentMusic: ->
    return unless @currentMusic
    createjs.Tween.removeTweens(@currentMusic)
    f = -> @stop()
    createjs.Tween.get(@currentMusic).to({volume: 0.0}, CROSSFADE_LENGTH).call(f)

  startNewMusic: (src, delay) ->
    @currentMusic = createjs.Sound.play(src, {interrupt: 'none', delay: 0, offset: 0, loop: -1, volume: 0.3}) if src
    return unless @currentMusic
    @currentMusic.volume = 0.0
    if me.get('music', true)
      createjs.Tween.get(@currentMusic).wait(delay).to({volume: MUSIC_VOLUME}, CROSSFADE_LENGTH)

  onMusicSettingChanged: ->
    @updateMusicVolume()

  updateMusicVolume: ->
    return unless @currentMusic
    createjs.Tween.removeTweens(@currentMusic)
    @currentMusic.volume = if me.get('music', true) then MUSIC_VOLUME else 0.0

  onRealTimePlaybackStarted: (e) ->
    @previousMusic = @currentMusic
    trackNumber = _.random 0, 2
    Backbone.Mediator.publish 'music-player:play-music', file: "/music/music_real_time_#{trackNumber}", play: true

  onRealTimePlaybackEnded: (e) ->
    @fadeOutCurrentMusic()
    if @previousMusic
      @currentMusic = @previousMusic
      @restartCurrentMusic()
      if @currentMusic.volume
        createjs.Tween.get(@currentMusic).wait(5000).to({volume: MUSIC_VOLUME}, CROSSFADE_LENGTH)

  onEnterMenu: (e) ->
    return if @inMenu
    @inMenu = true
    @previousMusic = @currentMusic
    file = "/music/music-menu"
    Backbone.Mediator.publish 'music-player:play-music', file: file, play: true, delay: 1000

  onExitMenu: (e) ->
    return unless @inMenu
    @inMenu = false
    @fadeOutCurrentMusic()
    if @previousMusic
      @currentMusic = @previousMusic
      @restartCurrentMusic()

  onSetVolume: (e) ->
    return unless e.volume and @lastMusicEventIgnoredWhileMuted
    @onPlayMusic @lastMusicEventIgnoredWhileMuted
    @lastMusicEventIgnoredWhileMuted = null

  destroy: ->
    me.off 'change:music', @onMusicSettingChanged, @
    @fadeOutCurrentMusic()
    super()
