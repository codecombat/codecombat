SpellView = require './SpellView'
SpellTopBarView = require './SpellTopBarView'
{me} = require 'core/auth'
{createAetherOptions} = require 'lib/aether_utils'
utils = require 'core/utils'

module.exports = class Spell
  loaded: false
  view: null
  topBarView: null

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
    @level = options.level
    @createFromProgrammableMethod options.programmableMethod, options.language
    if @canRead()  # We can avoid creating these views if we'll never use them.
      @view = new SpellView {spell: @, level: options.level, session: @session, otherSession: @otherSession, worker: @worker, god: options.god, @supermodel, levelID: options.levelID}
      @view.render()  # Get it ready and code loaded in advance
      @topBarView = new SpellTopBarView
        hintsState: options.hintsState
        spell: @
        supermodel: @supermodel
        codeLanguage: @language
        level: options.level
        session: options.session
        courseID: options.courseID
        courseInstanceID: options.courseInstanceID
      @topBarView.render()
    Backbone.Mediator.publish 'tome:spell-created', spell: @

  createFromProgrammableMethod: (programmableMethod, codeLanguage) ->
    p = programmableMethod
    @commentI18N = p.i18n
    @commentContext = p.context
    @languages = p.languages ? {}
    @languages.javascript ?= p.source
    @name = p.name
    @permissions = read: p.permissions?.read ? [], readwrite: p.permissions?.readwrite ? ['humans']  # teams
    @team = @permissions.readwrite[0] ? 'common'
    if @canWrite()
      @setLanguage codeLanguage
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

  destroy: ->
    @view?.destroy()
    @topBarView?.destroy()
    @thang = null
    @worker = null

  setLanguage: (@language) ->
    @language = 'html' if @level.isType('web-dev')
    @displayCodeLanguage = utils.capitalLanguages[@language]
    @originalSource = @languages[@language] ? @languages.javascript
    @originalSource = @addPicoCTFProblem() if window.serverConfig.picoCTF

    if @level.isType('web-dev')
      # Pull apart the structural wrapper code and the player code, remember the wrapper code, and strip indentation on player code.
      playerCode = utils.extractPlayerCodeTag(@originalSource)
      @wrapperCode = @originalSource.replace /<playercode>[\s\S]*<\/playercode>/, '☃'  # ☃ serves as placeholder for constructHTML
      @originalSource = playerCode

    # Translate comments chosen spoken language.
    return unless @commentContext
    context = $.extend true, {}, @commentContext

    if @language is 'lua'
      for k,v of context
        context[k] = v.replace /\b([a-zA-Z]+)\.([a-zA-Z_]+\()/, '$1:$2'

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
      @wrapperCode = _.template @wrapperCode, context
    catch e
      console.error "Couldn't create example code template of", @originalSource, "\nwith context", context, "\nError:", e

    if /loop/.test(@originalSource) and @level.isType('course', 'course-ladder')
      # Temporary hackery to make it look like we meant while True: in our sample code until we can update everything
      @originalSource = switch @language
        when 'python' then @originalSource.replace /loop:/, 'while True:'
        when 'javascript' then @originalSource.replace /loop {/, 'while (true) {'
        when 'lua' then @originalSource.replace /loop\n/, 'while true then\n'
        when 'coffeescript' then @originalSource
        else @originalSource

  constructHTML: (source) ->
    @wrapperCode.replace '☃', source

  addPicoCTFProblem: ->
    return @originalSource unless problem = @level.picoCTFProblem
    description = """
      -- #{problem.name} --
      #{problem.description}
    """.replace /<p>(.*?)<\/p>/gi, '$1'
    ("// #{line}" for line in description.split('\n')).join('\n') + '\n' + @originalSource

  addThang: (thang) ->
    if @thang?.thang.id is thang.id
      @thang.thang = thang
    else
      @thang = {thang: thang, aether: @createAether(thang), castAether: null}

  removeThangID: (thangID) ->
    @thang = null if @thang?.thang.id is thangID

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
    unless @language is 'html'
      @thang?.aether.transpile source
      @session.lastAST = @thang?.aether.ast
    null

  # NOTE: By default, I think this compares the current source code with the source *last saved to the server* (not the last time it was run)
  hasChanged: (newSource=null, currentSource=null) ->
    (newSource ? @originalSource) isnt (currentSource ? @source)

  hasChangedSignificantly: (newSource=null, currentSource=null, cb) ->
    unless aether = @thang?.aether
      console.error @toString(), 'couldn\'t find a spellThang with aether', @thang
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
    skipProtectAPI = @skipProtectAPI or not writable or @level.isType('game-dev')
    problemContext = @createProblemContext thang
    includeFlow = @level.isType('hero', 'hero-ladder', 'hero-coop', 'course', 'course-ladder', 'game-dev') and not skipProtectAPI
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
    @thang?.aether?.setLanguage @language
    @thang?.castAether = null
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

    @problemContext.thisValueAlias = if @level.isType('game-dev') then 'game' else 'hero'

    @problemContext

  reloadCode: ->
    # We pressed the reload button. Fetch our original source again in case it changed.
    return unless programmableMethod = @thang?.thang?.programmableMethods?[@name]
    @createFromProgrammableMethod programmableMethod, @language
