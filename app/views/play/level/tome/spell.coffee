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
    @worker = options.worker
    p = options.programmableMethod

    @name = p.name
    @permissions = read: p.permissions?.read ? [], readwrite: p.permissions?.readwrite ? []  # teams
    @source = @originalSource = p.source
    @parameters = p.parameters
    if @permissions.readwrite.length and sessionSource = @session.getSourceFor(@spellKey)
      @source = sessionSource
    @thangs = {}
    @view = new SpellView {spell: @, session: @session, worker: @worker}
    @view.render()  # Get it ready and code loaded in advance
    @tabView = new SpellListTabEntryView spell: @, supermodel: @supermodel
    @tabView.render()
    @team = @permissions.readwrite[0] ? "common"
    Backbone.Mediator.publish 'tome:spell-created', spell: @

  destroy: ->
    @view.destroy()
    @tabView.destroy()
    @thangs = null
    @worker = null

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
    [pure, problems] = [null, null]
    for thangID, spellThang of @thangs
      unless pure
        pure = spellThang.aether.transpile source
        problems = spellThang.aether.problems
        #console.log "aether transpiled", source.length, "to", pure.length, "for", thangID, @spellKey
      else
        spellThang.aether.pure = pure
        spellThang.aether.problems = problems
        #console.log "aether reused transpilation for", thangID, @spellKey
    null

  hasChanged: (newSource=null, currentSource=null) ->
    (newSource ? @originalSource) isnt (currentSource ? @source)

  hasChangedSignificantly: (newSource=null, currentSource=null, cb) ->
    for thangID, spellThang of @thangs
      aether = spellThang.aether
      break
    unless aether
      console.error @toString(), "couldn't find a spellThang with aether of", @thangs
      cb false
    workerMessage =
      function: "hasChangedSignificantly"
      a: (newSource ? @originalSource)
      spellKey: @spellKey
      b: (currentSource ? @source)
      careAboutLineNumbers: true
      careAboutLint: true
    @worker.addEventListener "message", (e) =>
      workerData = JSON.parse e.data
      if workerData.function is "hasChangedSignificantly" and workerData.spellKey is @spellKey
        @worker.removeEventListener "message", arguments.callee, false
        cb(workerData.hasChanged)
    @worker.postMessage JSON.stringify(workerMessage)

  createAether: (thang) ->
    aceConfig = me.get('aceConfig') ? {}
    aetherOptions =
      problems:
        jshint_W040: {level: "ignore"}
        jshint_W030: {level: "ignore"}  # aether_NoEffect instead
        jshint_W038: {level: "ignore"}  # eliminates hoisting problems
        jshint_W091: {level: "ignore"}  # eliminates more hoisting problems
        jshint_E043: {level: "ignore"}  # https://github.com/codecombat/codecombat/issues/813 -- since we can't actually tell JSHint to really ignore things
        jshint_Unknown: {level: "ignore"}  # E043 also triggers Unknown, so ignore that, too
        aether_MissingThis: {level: (if thang.requiresThis then 'error' else 'warning')}
      language: aceConfig.language ? 'javascript'
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
    #console.log "creating aether with options", aetherOptions
    aether = new Aether aetherOptions
    workerMessage =
      function: "createAether"
      spellKey: @spellKey
      options: aetherOptions
    @worker.postMessage JSON.stringify workerMessage
    aether

  updateLanguageAether: ->
    aceConfig = me.get('aceConfig') ? {}
    newLanguage = (aceConfig.language ? 'javascript')
    for thangId, spellThang of @thangs
      spellThang.aether?.setLanguage newLanguage
      spellThang.castAether = null
    workerMessage =
      function: "updateLanguageAether"
      newLanguage: newLanguage
    @worker.postMessage JSON.stringify workerMessage
    @transpile()

  toString: ->
    "<Spell: #{@spellKey}>"
