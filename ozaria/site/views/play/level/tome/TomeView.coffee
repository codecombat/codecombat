require('ozaria/site/styles/play/level/tome/tome.sass')
# There's one TomeView per Level. It has:
# - a CastButtonView, which has
#   - a cast button
#   - a submit/done button
# - for each spell (programmableMethod) (which is now just always only 'plan')
#   - a Spell, which has
#     - a Thang that uses that Spell, with an aether and a castAether
#     - a SpellView, which has
#       - tons of stuff; the meat
# - a SpellPaletteView, which has
#   - for each programmableProperty:
#     - a SpellPaletteEntryView
#
# The CastButtonView always shows.
# The SpellPaletteView shows the entries for the currently selected Programmable Thang.
# The SpellView shows the code and runtime state for the currently selected Spell and, specifically, Thang.
# You can switch a SpellView to showing the runtime state of another Thang sharing that Spell.
# SpellPaletteViews are destroyed and recreated whenever you switch Thangs.

CocoView = require 'views/core/CocoView'
template = require 'ozaria/site/templates/play/level/tome/tome.jade'
{me} = require 'core/auth'
Spell = require './Spell'
SpellPaletteView = require './SpellPaletteView'
CastButtonView = require './CastButtonView'
utils = require 'core/utils'

module.exports = class TomeView extends CocoView
  id: 'tome-view'
  template: template
  controlsEnabled: true
  cache: false

  subscriptions:
    'tome:spell-loaded': 'onSpellLoaded'
    'tome:cast-spell': 'onCastSpell'
    'tome:change-language': 'updateLanguageForAllSpells'
    'surface:sprite-selected': 'onSpriteSelected'
    'god:new-world-created': 'onNewWorld'
    'tome:comment-my-code': 'onCommentMyCode'
    'tome:select-primary-sprite': 'onSelectPrimarySprite'

  events:
    'click': 'onClick'

  constructor: (options) ->
    super options
    unless options.god or options.level.get('type') is 'web-dev'
      console.error "TomeView created with no God!"

  afterRender: ->
    super()
    @worker = @createWorker()
    programmableThangs = _.filter @options.thangs, (t) -> t.isProgrammable and t.programmableMethods
    if @options.level.isType('web-dev')
      if @fakeProgrammableThang = @createFakeProgrammableThang()
        programmableThangs = [@fakeProgrammableThang]
    @createSpells programmableThangs, programmableThangs[0]?.world  # Do before castButton
    @castButton = @insertSubView new CastButtonView spells: @spells, level: @options.level, session: @options.session, god: @options.god
    @teamSpellMap = @generateTeamSpellMap(@spells)
    unless programmableThangs.length
      @cast()
      warning = 'Warning: There are no Programmable Thangs in this level, which makes it unplayable.'
      noty text: warning, layout: 'topCenter', type: 'warning', killer: false, timeout: 15000, dismissQueue: true, maxVisible: 3
      console.warn warning
    delete @options.thangs

  onNewWorld: (e) ->
    programmableThangs = _.filter e.thangs, (t) -> t.isProgrammable and t.programmableMethods and t.inThangList
    @createSpells programmableThangs, e.world

  onCommentMyCode: (e) ->
    for spellKey, spell of @spells when spell.canWrite()
      console.log 'Commenting out', spellKey
      commentedSource = spell.view.commentOutMyCode() + 'Commented out to stop infinite loop.\n' + spell.getSource()
      spell.view.updateACEText commentedSource
      spell.view.recompile false
    @cast()

  createWorker: ->
    return null unless Worker?
    return null if window.application.isIPadApp  # Save memory!
    return new Worker('/javascripts/workers/aether_worker.js')

  generateTeamSpellMap: (spellObject) ->
    teamSpellMap = {}
    for spellName, spell of spellObject
      teamName = spell.team
      teamSpellMap[teamName] ?= []

      spellNameElements = spellName.split '/'
      thangName = spellNameElements[0]
      spellName = spellNameElements[1]

      teamSpellMap[teamName].push thangName if thangName not in teamSpellMap[teamName]

    return teamSpellMap

  createSpells: (programmableThangs, world) ->
    language = @options.session.get('codeLanguage') ? me.get('aceConfig')?.language ? 'python'
    pathPrefixComponents = ['play', 'level', @options.levelID, @options.session.id, 'code']
    @spells ?= {}
    @thangSpells ?= {}
    for thang in programmableThangs
      continue if @thangSpells[thang.id]?
      @thangSpells[thang.id] = []
      for methodName, method of thang.programmableMethods
        pathComponents = [thang.id, methodName]
        pathComponents[0] = _.string.slugify pathComponents[0]
        spellKey = pathComponents.join '/'
        @thangSpells[thang.id].push spellKey
        skipProtectAPI = utils.getQueryVariable 'skip_protect_api', false
        spell = @spells[spellKey] = new Spell
          hintsState: @options.hintsState
          programmableMethod: method
          spellKey: spellKey
          pathComponents: pathPrefixComponents.concat(pathComponents)
          session: @options.session
          otherSession: @options.otherSession
          supermodel: @supermodel
          skipProtectAPI: skipProtectAPI
          worker: @worker
          language: language
          spectateView: @options.spectateView
          spectateOpponentCodeLanguage: @options.spectateOpponentCodeLanguage
          observing: @options.observing
          levelID: @options.levelID
          level: @options.level
          god: @options.god
          courseID: @options.courseID
          courseInstanceID: @options.courseInstanceID

    for thangID, spellKeys of @thangSpells
      thang = @fakeProgrammableThang ? world.getThangByID thangID
      if thang
        @spells[spellKey].addThang thang for spellKey in spellKeys
      else
        delete @thangSpells[thangID]
        spell.removeThangID thangID for spell in @spells
    for spellKey, spell of @spells when not spell.canRead()  # Make sure these get transpiled (they have no views).
      spell.transpile()
      spell.loaded = true
    null

  onSpellLoaded: (e) ->
    for spellID, spell of @spells
      return unless spell.loaded
    justBegin = @options.level.isType('game-dev')
    @cast false, false, justBegin

  onCastSpell: (e) ->
    # A single spell is cast.
    @cast e?.preload, e?.realTime, e?.justBegin, e?.cinematic

  cast: (preload=false, realTime=false, justBegin=false, cinematic=false) ->
    return if @options.level.isType('web-dev')
    sessionState = @options.session.get('state') ? {}
    if realTime
      sessionState.submissionCount = (sessionState.submissionCount ? 0) + 1
      sessionState.flagHistory = _.filter sessionState.flagHistory ? [], (event) => event.team isnt (@options.session.get('team') ? 'humans')
      sessionState.lastUnsuccessfulSubmissionTime = new Date() if @options.level.get 'replayable'
      @options.session.set 'state', sessionState
    difficulty = sessionState.difficulty ? 0
    if @options.observing
      difficulty = Math.max 0, difficulty - 1  # Show the difficulty they won, not the next one.
    Backbone.Mediator.publish 'level:set-playing', {playing: false}
    Backbone.Mediator.publish 'tome:cast-spells', {
      @spells,
      preload,
      realTime,
      synchronous: @options.level.isType('game-dev') and not justBegin,
      justBegin,
      cinematic,
      difficulty,
      submissionCount: sessionState.submissionCount ? 0,
      flagHistory: sessionState.flagHistory ? [],
      god: @options.god,
      fixedSeed: @options.fixedSeed,
      keyValueDb: @options.session.get('keyValueDb') ? {}
    }

  onClick: (e) ->
    Backbone.Mediator.publish 'tome:focus-editor', {} unless $(e.target).parents('.popover').length

  onSpriteSelected: (e) ->
    return if @spellView and @options.level.get('type', true) in ['hero', 'hero-ladder', 'hero-coop', 'course', 'course-ladder', 'game-dev', 'web-dev']  # Never deselect the hero in the Tome.
    spell = @spellFor e.thang, e.spellName
    if spell?.canRead()
      @setSpellView spell, e.thang

  setSpellView: (spell, thang) ->
    unless spell.view is @spellView
      @spellView = spell.view
      @spellTopBarView = spell.topBarView
      @$el.find('#' + @spellView.id).after(@spellView.el).remove()
      @castButton?.attachTo @spellView
    @updateSpellPalette thang, spell
    @spellView?.setThang thang

  updateSpellPalette: (thang, spell) ->
    @options.playLevelView.updateSpellPalette thang, spell

  spellFor: (thang, spellName) ->
    return null unless thang?.isProgrammable
    return unless @thangSpells[thang.id]  # Probably in streaming mode, where we don't update until it's done.
    selectedThangSpells = (@spells[spellKey] for spellKey in @thangSpells[thang.id])
    if spellName
      spell = _.find selectedThangSpells, {name: spellName}
    else
      spell = _.find selectedThangSpells, (spell) -> spell.canWrite()
      spell ?= _.find selectedThangSpells, (spell) -> spell.canRead()
    spell

  reloadAllCode: ->
    if utils.getQueryVariable 'dev'
      @options.playLevelView.spellPaletteView.destroy()
      @updateSpellPalette @spellView.thang, @spellView.spell
    spell.view.reloadCode false for spellKey, spell of @spells when spell.view and (spell.team is me.team or (spell.team in ['common', 'neutral', null]))
    @cast false, false

  updateLanguageForAllSpells: (e) ->
    spell.updateLanguageAether e.language for spellKey, spell of @spells when spell.canWrite()
    if e.reload
      @reloadAllCode()
    else
      @cast()

  onSelectPrimarySprite: (e) ->
    if @options.level.isType('web-dev')
      @setSpellView @spells['hero-placeholder/plan'], @fakeProgrammableThang
      return
    # This is fired by PlayLevelView
    if @options.session.get('team') is 'ogres'
      Backbone.Mediator.publish 'level:select-sprite', thangID: 'Hero Placeholder 1'
    else
      Backbone.Mediator.publish 'level:select-sprite', thangID: 'Hero Placeholder'

  createFakeProgrammableThang: ->
    return null unless hero = _.find @options.level.get('thangs'), id: 'Hero Placeholder'
    return null unless programmableConfig = _.find(hero.components, (component) -> component.config?.programmableMethods).config
    usesHTMLConfig = _.find(hero.components, (component) -> component.config?.programmableHTMLProperties).config
    usesWebJavaScriptConfig = _.find(hero.components, (component) -> component.config?.programmableWebJavaScriptProperties)?.config
    usesJQueryConfig = _.find(hero.components, (component) -> component.config?.programmableJQueryProperties)?.config
    console.warn "Couldn't find usesHTML config; is it presented and not defaulted on the Hero Placeholder?" unless usesHTMLConfig
    thang =
      id: 'Hero Placeholder'
      isProgrammable: true
    thang = _.merge thang, programmableConfig, usesHTMLConfig, usesWebJavaScriptConfig, usesJQueryConfig
    thang

  destroy: ->
    spell.destroy() for spellKey, spell of @spells
    @worker?.terminate()
    super()
