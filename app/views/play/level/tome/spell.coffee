SpellView = require './spell_view'
SpellListTabEntryView = require './spell_list_tab_entry_view'
{me} = require 'lib/auth'

module.exports = class Spell
  loaded: false
  view: null
  entryView: null

  constructor: (options) ->
    @spellKey = options.spellKey
    @pathComponents = options.pathComponents
    @session = options.session
    @supermodel = options.supermodel
    @skipFlow = options.skipFlow
    @skipProtectAPI = options.skipProtectAPI
    p = options.programmableMethod

    @name = p.name
    @source = @session.getSourceFor(@spellKey) ? p.source
    @originalSource = p.source
    @parameters = p.parameters
    @permissions = read: p.permissions?.read ? [], readwrite: p.permissions?.readwrite ? []  # teams
    @thangs = {}
    @view = new SpellView {spell: @, session: @session}
    @view.render()  # Get it ready and code loaded in advance
    @tabView = new SpellListTabEntryView spell: @, supermodel: @supermodel
    @tabView.render()
    
  destroy: ->
    @view.destroy()
    @tabView.destroy()
    @thangs = null

  addThang: (thang) ->
    if @thangs[thang.id]
      @thangs[thang.id].thang = thang
    else
      @thangs[thang.id] = {thang: thang, aether: @createAether(thang), castAether: null}

  removeThangID: (thangID) ->
    delete @thangs[thangID]

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
      problems:
        jshint_W040: {level: "ignore"}
        jshint_W030: {level: "ignore"}  # aether_NoEffect instead
        aether_MissingThis: {level: (if thang.requiresThis then 'error' else 'warning')}
      functionName: @name
      functionParameters: @parameters
      yieldConditionally: thang.plan?
      requiresThis: thang.requiresThis
      # TODO: Gridmancer doesn't currently work with protectAPI, so hack it off
      protectAPI: not (@skipProtectAPI or window.currentView?.level.get('name').match("Gridmancer")) and @permissions.readwrite.length > 0  # If anyone can write to this method, we must protect it.
      includeFlow: not @skipFlow and @canRead()
        #callIndex: 0
        #timelessVariables: ['i']
        #statementIndex: 9001
    if not (me.team in @permissions.readwrite) or window.currentView?.sessionID is "52bfb88099264e565d001349"  # temp fix for debugger explosion bug
      #console.log "Turning off includeFlow for", @spellKey
      aetherOptions.includeFlow = false
    aether = new Aether aetherOptions
    aether

  toString: ->
    "<Spell: #{@spellKey}>"
