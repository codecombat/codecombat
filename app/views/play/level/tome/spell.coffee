SpellView = require './spell_view'
SpellListTabEntryView = require './spell_list_tab_entry_view'
{me} = require 'lib/auth'

module.exports = class Spell
  loaded: false
  view: null
  entryView: null

  constructor: (programmableMethod, @spellKey, @pathComponents, @session, @supermodel) ->
    p = programmableMethod
    @name = p.name
    @source = @session.getSourceFor(@spellKey) ? p.source
    @originalSource = p.source
    @parameters = p.parameters
    @permissions = read: p.permissions?.read ? [], readwrite: p.permissions?.readwrite ? []  # teams
    @thangs = {}
    @view = new SpellView {spell: @, session: @session}
    @view.render()  # Get it ready and code loaded in advance
    console.log 'spell creates tab entry view', @supermodel
    @tabView = new SpellListTabEntryView spell: @, supermodel: @supermodel
    @tabView.render()

  addThang: (thang) ->
    @thangs[thang.id] = {thang: thang, aether: @createAether(thang), castAether: null}

  canRead: (team) ->
    (team ? me.team) in @permissions.read or (team ? me.team) in @permissions.readwrite

  canWrite: (team) ->
    (team ? me.team) in @permissions.readwrite

  getSource: ->
    @view.getSource()

  transpile: (source) ->
    if source
      @source = source
    else
      source = @getSource()
    spellThang.aether.transpile source for thangID, spellThang of @thangs
    #for thangID, spellThang of @thangs
    #  console.log "aether transpiled", source, "to", spellThang.aether.pure
    #  break

  hasChanged: (newSource=null, currentSource=null) ->
    (newSource ? @originalSource) isnt (currentSource ? @source)

  hasChangedSignificantly: (newSource=null, currentSource=null) ->
    for thangID, spellThang of @thangs
      aether = spellThang.aether
      break
    unless aether
      console.error @toString(), "couldn't find a spellThang with aether of", @thangs
      return false
    aether.hasChangedSignificantly (newSource ? @originalSource), (currentSource ? @source), true, true

  createAether: (thang) ->
    aetherOptions =
      thisValue: thang.createUserContext()
      problems:
        jshint_W040: {level: "ignore"}
        aether_MissingThis: {level: (if thang.requiresThis then 'error' else 'warning')}
      functionName: @name
      functionParameters: @parameters
      yieldConditionally: thang.plan?
      requiresThis: thang.requiresThis
    if @name is 'chooseAction' or not (me.team in @permissions.readwrite) or thang.id is 'Thoktar'  # Gridmancer can't handle it
      #console.log "Turning off includeFlow for", @spellKey
      aetherOptions.includeFlow = false
    aether = new Aether aetherOptions
    aether

  toString: ->
    "<Spell: #{@spellKey}>"
