require('app/styles/artisans/student-solutions-view.sass')
RootView = require 'views/core/RootView'
template = require 'templates/artisans/student-solutions-view'

Campaigns = require 'collections/Campaigns'
Campaign = require 'models/Campaign'

Levels = require 'collections/Levels'
Level = require 'models/Level'
LevelSessions = require 'collections/LevelSessions'
ace = require('lib/aceContainer')
aceUtils = require 'core/aceUtils'
{createAetherOptions} = require 'lib/aether_utils'

unless typeof esper is 'undefined'
  realm = new esper().realm
  parser = realm.parser.bind(realm)

module.exports = class StudentSolutionsView extends RootView
  template: template
  id: 'student-solutions-view'

  events:
    'click #go-button': 'onClickGoButton'

  levelSlug: "eagle-eye"
  limit: 500
  languages: "python"

  initialize: () ->
    @validLanguages = ['python', 'javascript']
    @resetLevelInfo()
    @resetSolutionsInfo()

  resetLevelInfo: () ->
    @intended = {}
    @defaultcode = {}

  resetSolutionsInfo: () ->
    @doLanguages = if @languages is 'all' then ['javascript', 'python'] else [@languages]
    @stats = {}
    @stats['javascript'] = { total: 0, errors: 0 }
    @stats['python'] = { total: 0, errors: 0 }
    @sessions = null
    @solutions = {}
    @count = {}
    @errors = 0

  startFetchingData: ->
    @getLevelInfo()

  fetchSessions: () ->
    @resetSolutionsInfo()
    @getRecentSessions (sessions) =>
      return if @destroyed
      for session in @sessions.models
        session = session.attributes
        lang = session.codeLanguage
        continue unless lang in @doLanguages
        @stats[lang].total += 1
        src = session.code?['hero-placeholder'].plan
        unless src
          @stats[lang].errors += 1
          continue
        ast = @parseSource src, lang
        continue unless ast
        ast = @walkAST ast, @processASTNode
        hash = @hashString JSON.stringify(ast)
        @count[hash] ?= 0
        @count[hash] += 1
        @solutions[hash] ?= []
        @solutions[hash].push session

      oneOffs = 0
      tallyFn = (result, value, key) =>
        return result if value is 1 and oneOffs > 40
        oneOffs += 1 if value is 1
        result[value] ?= []
        result[value].push key
        result

      @talliedHashes = _.reduce(@count, tallyFn, {})
      @sortedTallyCounts = _.sortBy(_.keys(@talliedHashes), (v) -> parseInt(v)).reverse()
      @render()

  afterRender: ->
    super()
    editorElements = @$el.find('.ace')
    for el in editorElements
      lang = @$(el).data('language')
      editor = ace.edit el
      aceSession = editor.getSession()
      aceDoc = aceSession.getDocument()
      aceSession.setMode aceUtils.aceEditModes[lang]
      editor.setTheme 'ace/theme/textmate'
      editor.setReadOnly true

  getRecentSessions: (doneCallback) ->
    @sessions = new LevelSessions()
    data = {slug: @levelSlug, limit: @limit}
    if @doLanguages.length is 1
      data.codeLanguage = @doLanguages[0]
    @sessions.fetchRecentSessions data: data, method: 'POST', success: doneCallback

  getLevelInfo: () ->
    @level = @supermodel.getModel(Level, @levelSlug) or new Level _id: @levelSlug
    @supermodel.trackRequest @level.fetch()
    @level.on 'error', (@level, error) =>
      noty text: "Error loading level: #{error.statusText}", layout: 'center', type: 'error', killer: true
    if @level.loaded
      @onLevelLoaded @level
    else
      @listenToOnce @level, 'sync', @onLevelLoaded

  onClickGoButton: (event) ->
    event.preventDefault()
    @limit = @$('#sessionNum').val()
    @languages = @$('#languageSelect').val()
    @levelSlug = @$('#levelSlug').val()
    @startFetchingData()

  onLevelLoaded: (level) ->
    @resetLevelInfo()

    for solution in level.getSolutions()
      continue unless solution.source and solution.language in @validLanguages
      ast = @parseSource solution.source, solution.language
      continue unless ast
      ast = @walkAST ast, @processASTNode
      hash = @hashString JSON.stringify(ast)
      @intended[solution.language] = hash: hash, source: solution.source

    defaults = @getDefaultCode level
    for language, source of @getDefaultCode level
      continue unless source and language in @validLanguages
      ast = @parseSource source, language
      continue unless ast
      ast = @walkAST ast, @processASTNode
      hash = @hashString JSON.stringify(ast)
      @defaultcode[language] = hash: hash, source: source
    @fetchSessions()

  getDefaultCode: (level) ->

    parseTemplate = (src, context) =>
      try
        res = _.template(src)(context)
        return res
      catch e
        console.warn "Template Error"
        console.log src
        return src

    # TODO: put this into Level? if so, also use it in TeacherCourseSolutionView
    programmableComponentOriginal = '524b7b5a7fc0f6d51900000e'
    heroPlaceholder = _.find level.get('thangs'), id: 'Hero Placeholder'
    comp = _.find heroPlaceholder?.components, original: programmableComponentOriginal
    programmableMethod = comp?.config.programmableMethods.plan
    result = {}

    # javascript
    if programmableMethod.source
      src = programmableMethod.source
      src = parseTemplate(src, programmableMethod.context)
      result['javascript'] = src
    # non-javascript
    for key in _.keys(programmableMethod.languages)
      continue unless key in ['python']
      src = programmableMethod.languages[key]
      src = parseTemplate(src, programmableMethod.context)
      result[key] = src

    result

  parseSource: (src, lang) =>
    if lang is 'python'
      aether = new Aether language: 'python'
      tsrc = aether.transpile(src)
      ast = aether.ast
      # TODO: continue if error
      # aether.problems?
    if lang is 'javascript'
      try
        ast = parser(src)
      catch e
        @stats[lang].errors += 1
        return null
    ast

  # Salvaged from dying Aether project
  walkAST: (node, fn) ->
    for key, child of node
      if _.isArray child
        for grandchild in child
          if _.isString grandchild?.type
            @walkAST grandchild, fn
      else if _.isString child?.type
        @walkAST child, fn
    fn node

  processASTNode: (node) =>
    return unless node?
    delete node.range if node.range
    delete node.loc if node.loc
    delete node.originalRange if node.originalRange
    node

  hashString: (str) ->
    (str.charCodeAt i for i in [0...str.length]).reduce(((hash, char) -> ((hash << 5) + hash) + char), 5381)  # hash * 33 + c
