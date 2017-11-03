CocoClass = require 'core/CocoClass'
cache = {}
{me} = require 'core/auth'
createjs = require 'lib/createjs-parts'

# Top 20 obscene words (plus 'fiddlesticks') will trigger swearing Simlish with *beeps*.
# Didn't like leaving so much profanity lying around in the source, so rot13'd.
rot13 = (s) -> s.replace /[A-z]/g, (c) -> String.fromCharCode c.charCodeAt(0) + (if c.toUpperCase() <= 'M' then 13 else -13)
swears = (rot13 s for s in ['nefrubyr', 'nffubyr', 'onfgneq', 'ovgpu', 'oybbql', 'obyybpxf', 'ohttre', 'pbpx', 'penc', 'phag', 'qnza', 'qnea', 'qvpx', 'qbhpur', 'snt', 'shpx', 'cvff', 'chffl', 'fuvg', 'fyhg', 'svqqyrfgvpxf'])

soundPlugins = [createjs.WebAudioPlugin, createjs.HTMLAudioPlugin]
createjs.Sound.registerPlugins(soundPlugins)

class Manifest
  constructor: -> @storage = {}

  add: (filename, group='misc') ->
    name = name or filename
    @storage[group] = [] unless @storage[group]?
    return if filename in @storage[group]
    @storage[group].push(filename)

  addPrimarySound: (filename) -> @add(filename, 'primarySounds')
  addSecondarySound: (filename) -> @add(filename, 'secondarySounds')
  getData: -> return @storage

class Media
  constructor: (name) -> @name = name if name

  loaded: false
  data: null
  progress: 0.0
  error: null
  name: ''

class AudioPlayer extends CocoClass
  subscriptions:
    'audio-player:play-sound': (e) -> @playInterfaceSound e.trigger, e.volume

  constructor: () ->
    super()
    @ext = if createjs.Sound.capabilities.mp3 then '.mp3' else '.ogg'
    @camera = null
    @listenToSound()
    @createNewManifest()
    @soundsToPlayWhenLoaded = {}

  createNewManifest: ->
    @manifest = new Manifest()

  listenToSound: ->
    # I would like to go through PreloadJS to organize loading by queue, but
    # when I try to set it up, I get an error with the Sound plugin.
    # So for now, we'll just load through SoundJS instead.
    createjs.Sound.on 'fileload', @onSoundLoaded

  applyPanning: (options, pos) ->
    sup = @camera.worldToSurface pos
    svp = @camera.surfaceViewport
    pan = Math.max -1, Math.min 1, ((sup.x - svp.x) - svp.width / 2) / svp.width
    pan = 0 if _.isNaN pan
    dst = @camera.distanceRatioTo pos
    dst = 0.8 if _.isNaN dst
    vol = Math.min 1, options.volume / Math.pow (dst + 0.2), 2
    volume: options.volume, delay: options.delay, pan: pan

  # PUBLIC LOADING METHODS

  soundForDialogue: (message, soundTriggers) ->
    if _.isArray message then message = message.join ' '
    return message unless _.isString message
    return null unless say = soundTriggers?.say
    message = _.string.slugify message
    return sound if sound = say[message]
    if _.string.startsWith message, 'attack'
      return sound if sound = say.attack
    if message.indexOf("i-dont-see-anyone") isnt -1
      return sound if sound = say['i-dont-see-anyone']
    if message.indexOf("i-see-you") isnt -1
      return sound if sound = say['i-see-you']
    if message.indexOf("repeating-loop") isnt -1
      return sound if sound = say['repeating-loop']
    if /move(up|down|left|right)/.test message
      return sound if sound = say["move-#{message[4...]}"]
    defaults = say.defaultSimlish
    if say.swearingSimlish?.length and _.find(swears, (s) -> message.search(s) isnt -1)
      defaults = say.swearingSimlish
    return null unless defaults?.length
    return defaults[message.length % defaults.length]

  preloadInterfaceSounds: (names) ->
    return unless me.get 'volume'
    for name in names
      filename = "/file/interface/#{name}#{@ext}"
      @preloadSound filename, name

  playInterfaceSound: (name, volume=1) ->
    return unless volume and me.get 'volume'
    filename = "/file/interface/#{name}#{@ext}"
    if @hasLoadedSound filename
      @playSound name, volume
    else
      @preloadInterfaceSounds [name] unless filename of cache
      @soundsToPlayWhenLoaded[name] = volume

  playSound: (name, volume=1, delay=0, pos=null) ->
    return console.error 'Trying to play empty sound?' unless name
    return unless volume and me.get 'volume'
    audioOptions = {volume: volume, delay: delay}
    filename = if _.string.startsWith(name, '/file/') then name else '/file/' + name
    unless @hasLoadedSound filename
      @soundsToPlayWhenLoaded[name] = audioOptions.volume
    audioOptions = @applyPanning audioOptions, pos if @camera and not @camera.destroyed and pos
    instance = createjs.Sound.play name, audioOptions
    instance

  hasLoadedSound: (filename, name) ->
    return false unless filename of cache
    return false unless createjs.Sound.loadComplete filename
    true

  preloadSoundReference: (sound) ->
    return unless me.get 'volume'
    return unless name = @nameForSoundReference sound
    filename = '/file/' + name
    @preloadSound filename, name
    filename

  nameForSoundReference: (sound) ->
    sound[@ext.slice(1)]  # mp3 or ogg

  preloadSound: (filename, name) ->
    return unless filename
    return if filename of cache
    name ?= filename
    # SoundJS flips out if you try to register the same file twice
    result = createjs.Sound.registerSound(filename, name, 1)  # 1: 1 channel
    cache[filename] = new Media(name)

  # PROGRESS CALLBACKS

  onSoundLoaded: (e) =>
    media = cache[e.src]
    return if not media
    media.loaded = true
    media.progress = 1.0
    if volume = @soundsToPlayWhenLoaded[media.name]
      @playSound media.name, volume
      @soundsToPlayWhenLoaded[media.name] = false
    @notifyProgressChanged()

  onSoundLoadError: (e) =>
    console.error 'Could not load sound', e

  notifyProgressChanged: ->
    Backbone.Mediator.publish('audio-player:loaded', {sender: @})

  getStatus: (src) ->
    return cache[src] or null


module.exports = new AudioPlayer()
