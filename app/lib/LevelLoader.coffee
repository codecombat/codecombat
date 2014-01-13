Level = require 'models/Level'
CocoClass = require 'lib/CocoClass'
AudioPlayer = require 'lib/AudioPlayer'
LevelSession = require 'models/LevelSession'
ThangType = require 'models/ThangType'
app = require 'application'

# This is an initial stab at unifying loading and setup into a single place which can
# monitor everything and keep a LoadingScreen visible overall progress.
#
# Would also like to incorporate into here:
#  * World Building
#  * Sprite map generation
#  * Connecting to Firebase

module.exports = class LevelLoader extends CocoClass

  spriteSheetsBuilt: 0
  spriteSheetsToBuild: 0

  subscriptions:
    'god:new-world-created': 'loadSoundsForWorld'

  constructor: (@levelID, @supermodel, @sessionID) ->
    super()
    @loadSession()
    @loadLevelModels()
    @loadAudio()
    @playJingle()
    setTimeout (=> @update()), 1 # lets everything else resolve first

  playJingle: ->
    jingles = ["ident_1", "ident_2"]
    AudioPlayer.playInterfaceSound jingles[Math.floor Math.random() * jingles.length]

  # Session Loading

  loadSession: ->
    url = if @sessionID then "/db/level_session/#{@sessionID}" else "/db/level/#{@levelID}/session"
    @session = new LevelSession()
    @session.url = -> url
    @session.fetch()
    @session.once 'sync', @onSessionLoaded

  onSessionLoaded: =>
    # TODO: maybe have all non versioned models do this? Or make it work to PUT/PATCH to relative urls
    @session.url = -> '/db/level.session/' + @id
    @update()

  # Supermodel (Level) Loading

  loadLevelModels: ->
    @supermodel.once 'loaded-all', @onSupermodelLoadedAll
    @supermodel.on 'loaded-one', @onSupermodelLoadedOne
    @supermodel.once 'error', @onSupermodelError
    @level = @supermodel.getModel(Level, @levelID) or new Level _id: @levelID

    @supermodel.shouldPopulate = (model) =>
      # if left unchecked, the supermodel would load this level
      # and every level next on the chain. This limits the population
      handles = [model.id, model.get 'slug']
      return model.constructor.className isnt "Level" or @levelID in handles

    @supermodel.populateModel @level

  onSupermodelError: =>
    msg = $.i18n.t('play_level.level_load_error',
      defaultValue: "Level could not be loaded.")
    @$el.html('<div class="alert">' + msg + '</div>')

  onSupermodelLoadedOne: (e) =>
    @notifyProgress()
    if e.model.type() is 'ThangType'
      thangType = e.model
      options = {async: true}
      if thangType.get('name') is 'Wizard'
        options.colorConfig = me.get('wizard')?.colorConfig or {}
      building = thangType.buildSpriteSheet options
      if building
        @spriteSheetsToBuild += 1
        thangType.on 'build-complete', =>
          @spriteSheetsBuilt += 1
          @notifyProgress()

  onSupermodelLoadedAll: =>
    @trigger 'loaded-supermodel'
    @stopListening(@supermodel)
    @update()

  # Things to do when either the Session or Supermodel load

  update: ->
    @notifyProgress()

    return if @updateCompleted
    return unless @supermodel.finished() and @session.loaded
    @denormalizeSession()
    @loadLevelSounds()
    app.tracker.updatePlayState(@level, @session)
    @updateCompleted = true

  denormalizeSession: ->
    return if @session.get 'levelName'
    patch =
      'levelName': @level.get('name')
      'levelID': @level.get('slug') or @level.id
    if me.id is @session.get 'creator'
      patch.creatorName = me.get('name')

    @session.set key, value for key, value of patch
    tempSession = new LevelSession _id: @session.id
    tempSession.save(patch, {patch: true})
    @sessionDenormalized = true

  # Initial Sound Loading

  loadAudio: ->
    AudioPlayer.preloadInterfaceSounds ["victory"]

  loadLevelSounds: ->
    scripts = @level.get 'scripts'
    return unless scripts

    for script in scripts when script.noteChain
      for noteGroup in script.noteChain when noteGroup.sprites
        for sprite in noteGroup.sprites when sprite.say?.sound
          AudioPlayer.preloadSoundReference(sprite.say.sound)

    thangTypes = @supermodel.getModels(ThangType)
    for thangType in thangTypes
      for trigger, sounds of thangType.get('soundTriggers') or {} when trigger isnt 'say'
        AudioPlayer.preloadSoundReference sound for sound in sounds

  # Dynamic sound loading

  loadSoundsForWorld: (e) ->
    world = e.world
    thangTypes = @supermodel.getModels(ThangType)
    for [spriteName, message] in world.thangDialogueSounds()
      continue unless thangType = _.find thangTypes, (m) -> m.get('name') is spriteName
      continue unless sound = AudioPlayer.soundForDialogue message, thangType.get('soundTriggers')
      filename = AudioPlayer.preloadSoundReference sound

  # everything else sound wise is loaded as needed as worlds are generated

  allDone: ->
    @supermodel.finished() and @session.loaded and @spriteSheetsBuilt is @spriteSheetsToBuild

  progress: ->
    return 0 unless @level.loaded
    overallProgress = 0
    supermodelProgress = @supermodel.progress()
    overallProgress += supermodelProgress * 0.7
    overallProgress += 0.1 if @session.loaded
    spriteMapProgress = if supermodelProgress is 1 then 0.2 else 0
    spriteMapProgress *= @spriteSheetsBuilt / @spriteSheetsToBuild if @spriteSheetsToBuild
    overallProgress += spriteMapProgress
    return overallProgress

  notifyProgress: ->
    Backbone.Mediator.publish 'level-loader:progress-changed', progress: @progress()
    @trigger 'ready-to-init-world' if @allDone()

  destroy: ->
    @supermodel.off 'loaded-one', @onSupermodelLoadedOne
    super()
