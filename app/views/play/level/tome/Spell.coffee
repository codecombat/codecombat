SpellView = require './SpellView'
SpellListTabEntryView = require './SpellListTabEntryView'
{me} = require 'core/auth'
{createAetherOptions} = require 'lib/aether_utils'
utils = require 'core/utils'

module.exports = class Spell
  loaded: false
  view: null
  entryView: null

  constructor: (options) ->
    @spellKey = options.spellKey
    @pathComponents = options.pathComponents
    @session = options.session
    @otherSession = options.otherSession
    @spectateView = options.spectateView
    @spectateOpponentCodeLanguage = options.spectateOpponentCodeLanguage
    @observing = options.observing
    @supermodel = options.supermodel
    @skipProtectAPI = options.skipProtectAPI
    @worker = options.worker
    @levelID = options.levelID
    @levelType = options.level.get('type', true)
    @level = options.level

    p = options.programmableMethod
    @commentI18N = p.i18n
    @commentContext = p.context
    @languages = p.languages ? {}
    @languages.javascript ?= p.source
    @name = p.name
    @permissions = read: p.permissions?.read ? [], readwrite: p.permissions?.readwrite ? []  # teams
    @team = @permissions.readwrite[0] ? 'common'
    if @canWrite()
      @setLanguage options.language
    else if @otherSession and @team is @otherSession.get 'team'
      @setLanguage @otherSession.get('submittedCodeLanguage') or @otherSession.get('codeLanguage')
    else
      @setLanguage 'javascript'

    @source = @originalSource
    @parameters = p.parameters
    if @permissions.readwrite.length and sessionSource = @session.getSourceFor(@spellKey)
      if sessionSource isnt '// Should fill in some default source\n'  # TODO: figure out why session is getting this default source in there and stop it
        @source = sessionSource
    if p.aiSource and not @otherSession and not @canWrite()
      @source = @originalSource = p.aiSource
      @isAISource = true
    @thangs = {}
    if @canRead()  # We can avoid creating these views if we'll never use them.
      @view = new SpellView {spell: @, level: options.level, session: @session, otherSession: @otherSession, worker: @worker, god: options.god, @supermodel}
      @view.render()  # Get it ready and code loaded in advance
      @tabView = new SpellListTabEntryView
        hintsState: options.hintsState
        spell: @
        supermodel: @supermodel
        codeLanguage: @language
        level: options.level
      @tabView.render()
    Backbone.Mediator.publish 'tome:spell-created', spell: @

  destroy: ->
    @view?.destroy()
    @tabView?.destroy()
    @thangs = null
    @worker = null

  setLanguage: (@language) ->
    #console.log 'setting language to', @language, 'so using original source', @languages[language] ? @languages.javascript
    @originalSource = @languages[@language] ? @languages.javascript
    @originalSource = @addPicoCTFProblem() if window.serverConfig.picoCTF

    # Translate comments chosen spoken language.
    return unless @commentContext
    context = $.extend true, {}, @commentContext
    if @commentI18N
      spokenLanguage = me.get 'preferredLanguage'
      while spokenLanguage
        spokenLanguage = spokenLanguage.substr 0, spokenLanguage.lastIndexOf('-') if fallingBack?
        if spokenLanguageContext = @commentI18N[spokenLanguage]?.context
          context = _.merge context, spokenLanguageContext
          break
        fallingBack = true
    try
      @originalSource = _.template @originalSource, context
    catch e
      console.error "Couldn't create example code template of", @originalSource, "\nwith context", context, "\nError:", e

    if /loop/.test(@originalSource) and @levelType in ['course', 'course-ladder']
      # Temporary hackery to make it look like we meant while True: in our sample code until we can update everything
      @originalSource = switch @language
        when 'python' then @originalSource.replace /loop:/, 'while True:'
        when 'javascript' then @originalSource.replace /loop {/, 'while (true) {'
        when 'lua' then @originalSource.replace /loop\n/, 'while true then\n'
        when 'coffeescript' then @originalSource
        else @originalSource

  addPicoCTFProblem: ->
    return @originalSource unless problem = @level.picoCTFProblem
    description = """
      -- #{problem.name} --
      #{problem.description}
    """.replace /<p>(.*?)<\/p>/gi, '$1'
    ("// #{line}" for line in description.split('\n')).join('\n') + '\n' + @originalSource

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
    @view?.getSource() ? @source

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
        #console.log 'aether transpiled', source.length, 'to', spellThang.aether.pure.length, 'for', thangID, @spellKey
      else
        spellThang.aether.raw = source
        spellThang.aether.pure = pure
        spellThang.aether.problems = problems
        #console.log 'aether reused transpilation for', thangID, @spellKey
    null

  hasChanged: (newSource=null, currentSource=null) ->
    (newSource ? @originalSource) isnt (currentSource ? @source)

  hasChangedSignificantly: (newSource=null, currentSource=null, cb) ->
    for thangID, spellThang of @thangs
      aether = spellThang.aether
      break
    unless aether
      console.error @toString(), 'couldn\'t find a spellThang with aether of', @thangs
      cb false
    if @worker
      workerMessage =
        function: 'hasChangedSignificantly'
        a: (newSource ? @originalSource)
        spellKey: @spellKey
        b: (currentSource ? @source)
        careAboutLineNumbers: true
        careAboutLint: true
      @worker.addEventListener 'message', (e) =>
        workerData = JSON.parse e.data
        if workerData.function is 'hasChangedSignificantly' and workerData.spellKey is @spellKey
          @worker.removeEventListener 'message', arguments.callee, false
          cb(workerData.hasChanged)
      @worker.postMessage JSON.stringify(workerMessage)
    else
      cb(aether.hasChangedSignificantly((newSource ? @originalSource), (currentSource ? @source), true, true))

  createAether: (thang) ->
    writable = @permissions.readwrite.length > 0 and not @isAISource
    skipProtectAPI = @skipProtectAPI or not writable or @levelType in ['game-dev']
    problemContext = @createProblemContext thang
    includeFlow = (@levelType in ['hero', 'hero-ladder', 'hero-coop', 'course', 'course-ladder', 'game-dev']) and not skipProtectAPI
    aetherOptions = createAetherOptions
      functionName: @name
      codeLanguage: @language
      functionParameters: @parameters
      skipProtectAPI: skipProtectAPI
      includeFlow: includeFlow
      problemContext: problemContext
      useInterpreter: true
    aether = new Aether aetherOptions
    if @worker
      workerMessage =
        function: 'createAether'
        spellKey: @spellKey
        options: aetherOptions
      @worker.postMessage JSON.stringify workerMessage
    aether

  updateLanguageAether: (@language) ->
    for thangId, spellThang of @thangs
      spellThang.aether?.setLanguage @language
      spellThang.castAether = null
      Backbone.Mediator.publish 'tome:spell-changed-language', spell: @, language: @language
    if @worker
      workerMessage =
        function: 'updateLanguageAether'
        newLanguage: @language
      @worker.postMessage JSON.stringify workerMessage
    @transpile()

  toString: ->
    "<Spell: #{@spellKey}>"

  createProblemContext: (thang) ->
    # Create problemContext Aether can use to craft better error messages
    # stringReferences: values that should be referred to as a string instead of a variable (e.g. "Brak", not Brak)
    # thisMethods: methods available on the 'this' object
    # thisProperties: properties available on the 'this' object
    # commonThisMethods: methods that are available sometimes, but not awlays

    # NOTE: Assuming the first createProblemContext call has everything we need, and we'll use that forevermore
    return @problemContext if @problemContext?

    @problemContext = { stringReferences: [], thisMethods: [], thisProperties: [] }
    # TODO: These should be read from the database
    @problemContext.commonThisMethods = ['moveRight', 'moveLeft', 'moveUp', 'moveDown', 'attack', 'findNearestEnemy', 'buildXY', 'moveXY', 'say', 'move', 'distance', 'findEnemies', 'findFriends', 'addFlag', 'findFlag', 'removeFlag', 'findFlags', 'attackRange', 'cast', 'buildTypes', 'jump', 'jumpTo', 'attackXY']
    return @problemContext unless thang?

    # Populate stringReferences
    for key, value of thang.world?.thangMap
      if (value.isAttackable or value.isSelectable) and value.id not in @problemContext.stringReferences
        @problemContext.stringReferences.push value.id

    # Populate thisMethods and thisProperties
    if thang.programmableProperties?
      for prop in thang.programmableProperties
        if _.isFunction(thang[prop])
          @problemContext.thisMethods.push prop
        else
          @problemContext.thisProperties.push prop

    # TODO: See SpellPaletteView.createPalette() for other interesting contextual properties

    @problemContext
