# There's one TomeView per Level. It has:
# - a CastButtonView, which has
#   - a cast button
#   - an autocast settings options button
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

View = require 'views/kinds/CocoView'
template = require 'templates/play/level/tome/tome'
{me} = require 'lib/auth'
Spell = require './spell'
SpellListView = require './spell_list_view'
ThangListView = require './thang_list_view'
SpellPaletteView = require './spell_palette_view'
CastButtonView = require './cast_button_view'

window.SHIM_WORKER_PATH = '/javascripts/workers/catiline_worker_shim.coffee'

module.exports = class TomeView extends View
  id: 'tome-view'
  template: template
  controlsEnabled: true
  cache: false

  subscriptions:
    'tome:spell-loaded': "onSpellLoaded"
    'tome:cast-spell': "onCastSpell"
    'tome:toggle-spell-list': 'onToggleSpellList'
    'tome:change-language': 'updateLanguageForAllSpells'
    'surface:sprite-selected': 'onSpriteSelected'
    'god:new-world-created': 'onNewWorld'
    'tome:comment-my-code': 'onCommentMyCode'

  events:
    'click #spell-view': 'onSpellViewClick'
    'click': 'onClick'

  afterRender: ->
    super()
    @worker = @createWorker()
    programmableThangs = _.filter @options.thangs, 'isProgrammable'
    if programmableThangs.length
      @createSpells programmableThangs, programmableThangs[0].world  # Do before spellList, thangList, and castButton
      @spellList = @insertSubView new SpellListView spells: @spells, supermodel: @supermodel
      @thangList = @insertSubView new ThangListView spells: @spells, thangs: @options.thangs, supermodel: @supermodel
      @castButton = @insertSubView new CastButtonView spells: @spells, levelID: @options.levelID
      @teamSpellMap = @generateTeamSpellMap(@spells)
    else
      @cast()
      console.warn "Warning: There are no Programmable Thangs in this level, which makes it unplayable."
    delete @options.thangs

  onNewWorld: (e) ->
    thangs = _.filter e.world.thangs, 'isSelectable'
    programmableThangs = _.filter thangs, 'isProgrammable'
    @createSpells programmableThangs, e.world
    @thangList.adjustThangs @spells, thangs
    @spellList.adjustSpells @spells

  onCommentMyCode: (e) ->
    for spellKey, spell of @spells when spell.canWrite()
      console.log "Commenting out", spellKey
      commentedSource = 'return;  // Commented out to stop infinite loop.\n' + spell.getSource()
      spell.view.updateACEText commentedSource
      spell.view.recompile false
    @cast()

  createWorker: ->
    return
    # In progress
    worker = cw
      initialize: (scope) ->
        self.window = self
        self.global = self
        console.log 'Tome worker initialized.'
      doIt: (data, callback, scope) ->
        console.log 'doing', what
        try
          importScripts '/javascripts/tome_aether.js'
        catch err
          console.log err.toString()
        a = new Aether()
        callback 'good'
        undefined
    onAccepted = (s) -> console.log 'accepted', s
    onRejected = (s) -> console.log 'rejected', s
    worker.doIt('hmm').then onAccepted, onRejected
    worker

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
          skipProtectAPI = @getQueryVariable "skip_protect_api", not @options.ladderGame
          skipFlow = @getQueryVariable "skip_flow", @options.levelID is 'brawlwood' or @options.levelID is 'resource-gathering-multiplayer'
          spell = @spells[spellKey] = new Spell programmableMethod: method, spellKey: spellKey, pathComponents: pathPrefixComponents.concat(pathComponents), session: @options.session, supermodel: @supermodel, skipFlow: skipFlow, skipProtectAPI: skipProtectAPI, worker: @worker
    for thangID, spellKeys of @thangSpells
      thang = world.getThangByID thangID
      if thang
        @spells[spellKey].addThang thang for spellKey in spellKeys
      else
        delete @thangSpells[thangID]
        spell.removeThangID thangID for spell in @spells
    null

  onSpellLoaded: (e) ->
    for spellID, spell of @spells
      return unless spell.loaded
    @cast()

  onCastSpell: (e) ->
    # A single spell is cast.
    # Hmm; do we need to make sure other spells are all cast here?
    @cast()

  cast: ->
    if @options.levelID is 'brawlwood'
      # For performance reasons, only includeFlow on the currently Thang.
      for spellKey, spell of @spells
        for thangID, spellThang of spell.thangs
          hadFlow = Boolean spellThang.aether.options.includeFlow
          willHaveFlow = spellThang is @spellView?.spellThang
          spellThang.aether.options.includeFlow = spellThang.aether.originalOptions.includeFlow = willHaveFlow
          spellThang.aether.transpile spell.source unless hadFlow is willHaveFlow
          #console.log "set includeFlow to", spellThang.aether.options.includeFlow, "for", thangID, "of", spellKey
    Backbone.Mediator.publish 'tome:cast-spells', spells: @spells

  onToggleSpellList: (e) ->
    @spellList.rerenderEntries()
    @spellList.$el.toggle()

  onSpellViewClick: (e) ->
    @spellList.$el.hide()

  onClick: (e) ->
    Backbone.Mediator.publish 'focus-editor' unless $(e.target).parents('.popover').length

  clearSpellView: ->
    @spellView?.dismiss()
    @spellView?.$el.after('<div id="' + @spellView.id + '"></div>').detach()
    @spellView = null
    @spellTabView?.$el.after('<div id="' + @spellTabView.id + '"></div>').detach()
    @spellTabView = null
    @removeSubView @spellPaletteView if @spellPaletteView
    @spellPaletteView = null
    @castButton?.$el.hide()
    @thangList?.$el.show()

  onSpriteSelected: (e) ->
    thang = e.thang
    spellName = e.spellName
    @spellList?.$el.hide()
    return @clearSpellView() unless thang?.isProgrammable
    selectedThangSpells = (@spells[spellKey] for spellKey in @thangSpells[thang.id])
    if spellName
      spell = _.find selectedThangSpells, {name: spellName}
    else
      spell = @thangList.topSpellForThang thang
      #spell = selectedThangSpells[0]  # TODO: remember last selected spell for this thang
    return @clearSpellView() unless spell?.canRead()
    unless spell.view is @spellView
      @clearSpellView()
      @spellView = spell.view
      @spellTabView = spell.tabView
      @$el.find('#' + @spellView.id).after(@spellView.el).remove()
      @$el.find('#' + @spellTabView.id).after(@spellTabView.el).remove()
      @castButton.attachTo @spellView
      @thangList.$el.hide()
      Backbone.Mediator.publish 'tome:spell-shown', thang: thang, spell: spell
    @spellList.setThangAndSpell thang, spell
    @spellView?.setThang thang
    @spellTabView?.setThang thang
    if @spellPaletteView?.thang isnt thang
      @spellPaletteView = @insertSubView new SpellPaletteView thang: thang, supermodel: @supermodel
      @spellPaletteView.toggleControls {}, spell.view.controlsEnabled   # TODO: know when palette should have been disabled but didn't exist

  reloadAllCode: ->
    spell.view.reloadCode false for spellKey, spell of @spells when spell.team is me.team
    Backbone.Mediator.publish 'tome:cast-spells', spells: @spells

  updateLanguageForAllSpells: ->
    spell.updateLanguageAether() for spellKey, spell of @spells

  destroy: ->
    spell.destroy() for spellKey, spell of @spells
    @worker?._close()
    super()
