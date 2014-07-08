CocoClass = require 'lib/CocoClass'
AudioPlayer = require 'lib/AudioPlayer'
{me} = require 'lib/auth'

CROSSFADE_LENGTH = 1500

module.exports = class MusicPlayer extends CocoClass
  currentMusic: null
  standingBy: null

  subscriptions:
    'level-play-music': 'onPlayMusic'
    'audio-player:loaded': 'onAudioLoaded'

  constructor: ->
    super arguments...
    me.on 'change:music', @onMusicSettingChanged, @

  onAudioLoaded: ->
    @onPlayMusic(@standingBy) if @standingBy

  onPlayMusic: (e) ->
    src = e.file
    src = "/file#{e.file}#{AudioPlayer.ext}"
    if (not e.file) or src is @currentMusic?.src
      if e.play then @restartCurrentMusic() else @fadeOutCurrentMusic()
      return

    media = AudioPlayer.getStatus(src)
    if not media?.loaded
      AudioPlayer.preloadSound(src)
      @standingBy = e
      return

    @standingBy = null
    @fadeOutCurrentMusic()
    @startNewMusic(src) if e.play

  restartCurrentMusic: ->
    return unless @currentMusic
    @currentMusic.play('none', 0, 0, -1, 0.3)
    @updateMusicVolume()

  fadeOutCurrentMusic: ->
    return unless @currentMusic
    f = -> @stop()
    createjs.Tween.get(@currentMusic).to({volume: 0.0}, CROSSFADE_LENGTH).call(f)

  startNewMusic: (src) ->
    @currentMusic = createjs.Sound.play(src, 'none', 0, 0, -1, 0.3) if src
    return unless @currentMusic
    @currentMusic.volume = 0.0
    if me.get('music')
      createjs.Tween.get(@currentMusic).to({volume: 1.0}, CROSSFADE_LENGTH)

  onMusicSettingChanged: ->
    @updateMusicVolume()

  updateMusicVolume: ->
    return unless @currentMusic
    createjs.Tween.removeTweens(@currentMusic)
    @currentMusic.volume = if me.get('music') then 1.0 else 0.0

  destroy: ->
    me.off 'change:music', @onMusicSettingChanged, @
    super()
