# There's one TomeView per Level. It has:
# - a CastButtonView, which has
#   - a cast button
#   - a submit/done button
# - for each spell (programmableMethod):
#   - a Spell, which has
#     - a list of Thangs that share that Spell, with one aether per Thang per Spell
#     - a SpellView, which has
#       - tons of stuff; the meat
# - a SpellListView, which has
#   - for each spell:
#     - a SpellListEntryView, which has
#       - icons for each Thang
#       - the spell name
#       - a reload button
#       - documentation for that method (in a popover)
# - a SpellPaletteView, which has
#   - for each programmableProperty:
#     - a SpellPaletteEntryView
#
# The CastButtonView and SpellListView always show.
# The SpellPaletteView shows the entries for the currently selected Programmable Thang.
# The SpellView shows the code and runtime state for the currently selected Spell and, specifically, Thang.
# The SpellView obscures most of the SpellListView when present. We might mess with this.
# You can switch a SpellView to showing the runtime state of another Thang sharing that Spell.
# SpellPaletteViews are destroyed and recreated whenever you switch Thangs.
# The SpellListView shows spells to which your team has read or readwrite access.
# It doubles as a Thang selector, since it's there when nothing is selected.

CocoView = require 'views/core/CocoView'
template = require 'templates/play/level/tome/tome'
{me} = require 'core/auth'
Spell = require './Spell'
SpellListView = require './SpellListView'
SpellPaletteView = require './SpellPaletteView'
CastButtonView = require './CastButtonView'

module.exports = class TomeView extends CocoView
  id: 'tome-view'
  template: template
  controlsEnabled: true
  cache: false

  subscriptions:
    'tome:spell-loaded': 'onSpellLoaded'
    'tome:cast-spell': 'onCastSpell'
    'tome:toggle-spell-list': 'onToggleSpellList'
    'tome:change-language': 'updateLanguageForAllSpells'
    'surface:sprite-selected': 'onSpriteSelected'
    'god:new-world-created': 'onNewWorld'
    'tome:comment-my-code': 'onCommentMyCode'
    'tome:select-primary-sprite': 'onSelectPrimarySprite'

  events:
    'click #spell-view': 'onSpellViewClick'
    'click': 'onClick'

  afterRender: ->
    super()
    @worker = @createWorker()
    programmableThangs = _.filter @options.thangs, (t) -> t.isProgrammable and t.programmableMethods
    @createSpells programmableThangs, programmableThangs[0]?.world  # Do before spellList, thangList, and castButton
    unless @options.level.get('type', true) in ['hero', 'hero-ladder', 'hero-coop', 'course', 'course-ladder', 'game-dev']
      @spellList = @insertSubView new SpellListView spells: @spells, supermodel: @supermodel, level: @options.level
    @castButton = @insertSubView new CastButtonView spells: @spells, level: @options.level, session: @options.session, god: @options.god
    @teamSpellMap = @generateTeamSpellMap(@spells)
    unless programmableThangs.length
      @cast()
      warning = 'Warning: There are no Programmable Thangs in this level, which makes it unplayable.'
      noty text: warning, layout: 'topCenter', type: 'warning', killer: false, timeout: 15000, dismissQueue: true, maxVisible: 3
      console.warn warning
    delete @options.thangs

  onNewWorld: (e) ->
    thangs = _.filter e.world.thangs, 'inThangList'
    programmableThangs = _.filter thangs, (t) -> t.isProgrammable and t.programmableMethods
    @createSpells programmableThangs, e.world
    @spellList?.adjustSpells @spells

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
        if method.cloneOf
          pathComponents[0] = method.cloneOf  # referencing another Thang's method
        pathComponents[0] = _.string.slugify pathComponents[0]
        spellKey = pathComponents.join '/'
        @thangSpells[thang.id].push spellKey
        unless method.cloneOf
          skipProtectAPI = @getQueryVariable 'skip_protect_api', (@options.levelID in ['gridmancer', 'minimax-tic-tac-toe'])
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

    for thangID, spellKeys of @thangSpells
      thang = world.getThangByID thangID
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
    @cast()

  onCastSpell: (e) ->
    # A single spell is cast.
    @cast e?.preload, e?.realTime

  cast: (preload=false, realTime=false) ->
    sessionState = @options.session.get('state') ? {}
    if realTime
      sessionState.submissionCount = (sessionState.submissionCount ? 0) + 1
      sessionState.flagHistory = _.filter sessionState.flagHistory ? [], (event) => event.team isnt (@options.session.get('team') ? 'humans')
      sessionState.lastUnsuccessfulSubmissionTime = new Date() if @options.level.get 'replayable'
      @options.session.set 'state', sessionState
    difficulty = sessionState.difficulty ? 0
    if @options.observing
      difficulty = Math.max 0, difficulty - 1  # Show the difficulty they won, not the next one.
    Backbone.Mediator.publish 'tome:cast-spells', spells: @spells, preload: preload, realTime: realTime, submissionCount: sessionState.submissionCount ? 0, flagHistory: sessionState.flagHistory ? [], difficulty: difficulty, god: @options.god, fixedSeed: @options.fixedSeed

  onToggleSpellList: (e) ->
    @spellList?.rerenderEntries()
    @spellList?.$el.toggle()

  onSpellViewClick: (e) ->
    @spellList?.$el.hide()

  onClick: (e) ->
    Backbone.Mediator.publish 'tome:focus-editor', {} unless $(e.target).parents('.popover').length

  clearSpellView: ->
    @spellView?.dismiss()
    @spellView?.$el.after('<div id="' + @spellView.id + '"></div>').detach()
    @spellView = null
    @spellTabView?.$el.after('<div id="' + @spellTabView.id + '"></div>').detach()
    @spellTabView = null
    @removeSubView @spellPaletteView if @spellPaletteView
    @spellPaletteView = null
    @$el.find('#spell-palette-view').hide()
    @castButton?.$el.hide()

  onSpriteSelected: (e) ->
    return if @spellView and @options.level.get('type', true) in ['hero', 'hero-ladder', 'hero-coop', 'course', 'course-ladder', 'game-dev']  # Never deselect the hero in the Tome.
    thang = e.thang
    spellName = e.spellName
    @spellList?.$el.hide()
    return @clearSpellView() unless thang
    spell = @spellFor thang, spellName
    unless spell?.canRead()
      @clearSpellView()
      @updateSpellPalette thang, spell if spell
      return
    unless spell.view is @spellView
      @clearSpellView()
      @spellView = spell.view
      @spellTabView = spell.tabView
      @$el.find('#' + @spellView.id).after(@spellView.el).remove()
      @$el.find('#' + @spellTabView.id).after(@spellTabView.el).remove()
      @castButton?.attachTo @spellView
      Backbone.Mediator.publish 'tome:spell-shown', thang: thang, spell: spell
    @updateSpellPalette thang, spell
    @spellList?.setThangAndSpell thang, spell
    @spellView?.setThang thang
    @spellTabView?.setThang thang

  updateSpellPalette: (thang, spell) ->
    return unless thang and @spellPaletteView?.thang isnt thang and thang.programmableProperties or thang.apiProperties
    useHero = /hero/.test(spell.getSource()) or not /(self[\.\:]|this\.|\@)/.test(spell.getSource())
    @spellPaletteView = @insertSubView new SpellPaletteView { thang, @supermodel, programmable: spell?.canRead(), language: spell?.language ? @options.session.get('codeLanguage'), session: @options.session, level: @options.level, courseID: @options.courseID, courseInstanceID: @options.courseInstanceID, useHero }
    @spellPaletteView.toggleControls {}, spell.view.controlsEnabled if spell?.view   # TODO: know when palette should have been disabled but didn't exist

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
    spell.view.reloadCode false for spellKey, spell of @spells when spell.view and (spell.team is me.team or (spell.team in ['common', 'neutral', null]))
    @cast false, false

  updateLanguageForAllSpells: (e) ->
    spell.updateLanguageAether e.language for spellKey, spell of @spells when spell.canWrite()
    if e.reload
      @reloadAllCode()
    else
      @cast()

  onSelectPrimarySprite: (e) ->
    # This is only fired by PlayLevelView for hero levels currently
    # TODO: Don't hard code these hero names
    if @options.session.get('team') is 'ogres'
      Backbone.Mediator.publish 'level:select-sprite', thangID: 'Hero Placeholder 1'
    else
      Backbone.Mediator.publish 'level:select-sprite', thangID: 'Hero Placeholder'

  destroy: ->
    spell.destroy() for spellKey, spell of @spells
    @worker?.terminate()
    super()
