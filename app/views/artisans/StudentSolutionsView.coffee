RootView = require 'views/core/RootView'
template = require 'templates/artisans/student-solutions-view'

Campaigns = require 'collections/Campaigns'
Campaign = require 'models/Campaign'

Levels = require 'collections/Levels'
Level = require 'models/Level'
utils = require 'core/utils'
require 'vendor/aether-python'

unless typeof esper is 'undefined'
  parser = new esper().realm.parser

# Magic numbers for sha1
HEX_CHARS = '0123456789abcdef'.split('')
EXTRA = [
  -2147483648
  8388608
  32768
  128
]
SHIFT = [
  24
  16
  8
  0
]
blocks = []

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
    @sessions = []
    @solutions = {}
    @count = {}
    @errors = 0

  startFetchingData: ->
    @getLevelInfo()

  fetchSessions: () ->
    @resetSolutionsInfo()
    @getRecentSessions (sessions) =>
      @sessions = sessions
      for session in sessions
        lang = session.codeLanguage
        continue unless lang in @doLanguages
        @stats[lang].total += 1
        src = session.code?['hero-placeholder'].plan
        unless src
          @stats[lang].errors += 1
          continue
        ast = @parseSource src, lang
        continue unless ast
        ast = @walkASTCorrect ast, @processASTNode
        hash = @sha1(JSON.stringify(ast))
        @count[hash] ?= 0
        @count[hash] += 1
        @solutions[hash] ?= []
        @solutions[hash].push session

      tallyFn = (result, value, key) =>
        return result if value is 1
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
      aceSession.setMode utils.aceEditModes[lang]
      editor.setTheme 'ace/theme/textmate'
      editor.setReadOnly true

  # TODO: change LevelSessionHandler.getRecentSessions() to accept language as an option?
  getRecentSessions: (doneCallback) ->
    success = (data) =>
      return doneCallback(data) if @destroyed
      doneCallback(data)
    request = @supermodel.addRequestResource 'level_sessions_recent', {
      url: "/db/level.session/-/recent"
      data: {slug: @levelSlug, limit: @limit}
      method: 'POST'
      success: success
    }, 0
    request.load()

  getLevelInfo: () ->
    level = @supermodel.getModel(Level, @levelSlug) or new Level _id: @levelSlug
    level.on 'error', (level, error) =>
      noty text: "Error loading level: #{error.statusText}", layout: 'center', type: 'error', killer: true
    if level.loaded
      @onLevelLoaded level
    else
      @listenToOnce @supermodel.loadModel(level).model, 'sync', @onLevelLoaded

  onClickGoButton: (event) ->
    event.preventDefault()
    @limit = @$('#sessionNum').val()
    @languages = @$('#languageSelect').val()
    @levelSlug = @$('#levelSlug').val()
    @startFetchingData()

  onLevelLoaded: (level) ->
    @level = level
    @resetLevelInfo()

    for solution in level.getSolutions()
      continue unless solution.source and solution.language in @validLanguages
      ast = @parseSource solution.source, solution.language
      continue unless ast
      ast = @walkASTCorrect ast, @processASTNode
      hash = @sha1(JSON.stringify(ast))
      @intended[solution.language] = hash: hash, source: solution.source

    defaults = @getDefaultCode level
    for language, source of @getDefaultCode level
      continue unless source and language in @validLanguages
      ast = @parseSource source, language
      continue unless ast
      ast = @walkASTCorrect ast, @processASTNode
      hash = @sha1(JSON.stringify(ast))
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
    heroPlaceholder = level.get('thangs').filter((x) => x.id == 'Hero Placeholder').pop()
    comp = heroPlaceholder?.components.filter((x) => x.original.toString() == '524b7b5a7fc0f6d51900000e' ).pop()
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

  # TODO: expose walkASTCorrect from aether instead of recreating it here?
  walkASTCorrect: (node, fn) ->
    for key, child of node
      if _.isArray child
        for grandchild in child
          if _.isString grandchild?.type
            @walkASTCorrect grandchild, fn
      else if _.isString child?.type
        @walkASTCorrect child, fn
    fn node

  processASTNode: (node) =>
    return unless node?
    delete node.range if node.range
    delete node.loc if node.loc
    delete node.originalRange if node.originalRange
    node

  # TODO: replace this with a library if possible
  sha1: (message) ->
    notString = typeof message != 'string'
    if notString and message.constructor == ArrayBuffer
      message = new Uint8Array(message)
    h0 = undefined
    h1 = undefined
    h2 = undefined
    h3 = undefined
    h4 = undefined
    block = 0
    code = undefined
    end = false
    t = undefined
    f = undefined
    i = undefined
    j = undefined
    index = 0
    start = 0
    bytes = 0
    length = message.length
    h0 = 0x67452301
    h1 = 0xEFCDAB89
    h2 = 0x98BADCFE
    h3 = 0x10325476
    h4 = 0xC3D2E1F0
    loop
      blocks[0] = block
      blocks[16] = blocks[1] = blocks[2] = blocks[3] = blocks[4] = blocks[5] = blocks[6] = blocks[7] = blocks[8] = blocks[9] = blocks[10] = blocks[11] = blocks[12] = blocks[13] = blocks[14] = blocks[15] = 0
      if notString
        i = start
        while index < length and i < 64
          blocks[i >> 2] |= message[index] << SHIFT[i++ & 3]
          ++index
      else
        i = start
        while index < length and i < 64
          code = message.charCodeAt(index)
          if code < 0x80
            blocks[i >> 2] |= code << SHIFT[i++ & 3]
          else if code < 0x800
            blocks[i >> 2] |= (0xc0 | code >> 6) << SHIFT[i++ & 3]
            blocks[i >> 2] |= (0x80 | code & 0x3f) << SHIFT[i++ & 3]
          else if code < 0xd800 or code >= 0xe000
            blocks[i >> 2] |= (0xe0 | code >> 12) << SHIFT[i++ & 3]
            blocks[i >> 2] |= (0x80 | code >> 6 & 0x3f) << SHIFT[i++ & 3]
            blocks[i >> 2] |= (0x80 | code & 0x3f) << SHIFT[i++ & 3]
          else
            code = 0x10000 + ((code & 0x3ff) << 10 | message.charCodeAt(++index) & 0x3ff)
            blocks[i >> 2] |= (0xf0 | code >> 18) << SHIFT[i++ & 3]
            blocks[i >> 2] |= (0x80 | code >> 12 & 0x3f) << SHIFT[i++ & 3]
            blocks[i >> 2] |= (0x80 | code >> 6 & 0x3f) << SHIFT[i++ & 3]
            blocks[i >> 2] |= (0x80 | code & 0x3f) << SHIFT[i++ & 3]
          ++index
      bytes += i - start
      start = i - 64
      if index == length
        blocks[i >> 2] |= EXTRA[i & 3]
        ++index
      block = blocks[16]
      if index > length and i < 56
        blocks[15] = bytes << 3
        end = true
      j = 16
      while j < 80
        t = blocks[j - 3] ^ blocks[j - 8] ^ blocks[j - 14] ^ blocks[j - 16]
        blocks[j] = t << 1 | t >>> 31
        ++j
      a = h0
      b = h1
      c = h2
      d = h3
      e = h4
      j = 0
      while j < 20
        f = b & c | ~b & d
        t = a << 5 | a >>> 27
        e = t + f + e + 1518500249 + blocks[j] << 0
        b = b << 30 | b >>> 2
        f = a & b | ~a & c
        t = e << 5 | e >>> 27
        d = t + f + d + 1518500249 + blocks[j + 1] << 0
        a = a << 30 | a >>> 2
        f = e & a | ~e & b
        t = d << 5 | d >>> 27
        c = t + f + c + 1518500249 + blocks[j + 2] << 0
        e = e << 30 | e >>> 2
        f = d & e | ~d & a
        t = c << 5 | c >>> 27
        b = t + f + b + 1518500249 + blocks[j + 3] << 0
        d = d << 30 | d >>> 2
        f = c & d | ~c & e
        t = b << 5 | b >>> 27
        a = t + f + a + 1518500249 + blocks[j + 4] << 0
        c = c << 30 | c >>> 2
        j += 5
      while j < 40
        f = b ^ c ^ d
        t = a << 5 | a >>> 27
        e = t + f + e + 1859775393 + blocks[j] << 0
        b = b << 30 | b >>> 2
        f = a ^ b ^ c
        t = e << 5 | e >>> 27
        d = t + f + d + 1859775393 + blocks[j + 1] << 0
        a = a << 30 | a >>> 2
        f = e ^ a ^ b
        t = d << 5 | d >>> 27
        c = t + f + c + 1859775393 + blocks[j + 2] << 0
        e = e << 30 | e >>> 2
        f = d ^ e ^ a
        t = c << 5 | c >>> 27
        b = t + f + b + 1859775393 + blocks[j + 3] << 0
        d = d << 30 | d >>> 2
        f = c ^ d ^ e
        t = b << 5 | b >>> 27
        a = t + f + a + 1859775393 + blocks[j + 4] << 0
        c = c << 30 | c >>> 2
        j += 5
      while j < 60
        f = b & c | b & d | c & d
        t = a << 5 | a >>> 27
        e = t + f + e - 1894007588 + blocks[j] << 0
        b = b << 30 | b >>> 2
        f = a & b | a & c | b & c
        t = e << 5 | e >>> 27
        d = t + f + d - 1894007588 + blocks[j + 1] << 0
        a = a << 30 | a >>> 2
        f = e & a | e & b | a & b
        t = d << 5 | d >>> 27
        c = t + f + c - 1894007588 + blocks[j + 2] << 0
        e = e << 30 | e >>> 2
        f = d & e | d & a | e & a
        t = c << 5 | c >>> 27
        b = t + f + b - 1894007588 + blocks[j + 3] << 0
        d = d << 30 | d >>> 2
        f = c & d | c & e | d & e
        t = b << 5 | b >>> 27
        a = t + f + a - 1894007588 + blocks[j + 4] << 0
        c = c << 30 | c >>> 2
        j += 5
      while j < 80
        f = b ^ c ^ d
        t = a << 5 | a >>> 27
        e = t + f + e - 899497514 + blocks[j] << 0
        b = b << 30 | b >>> 2
        f = a ^ b ^ c
        t = e << 5 | e >>> 27
        d = t + f + d - 899497514 + blocks[j + 1] << 0
        a = a << 30 | a >>> 2
        f = e ^ a ^ b
        t = d << 5 | d >>> 27
        c = t + f + c - 899497514 + blocks[j + 2] << 0
        e = e << 30 | e >>> 2
        f = d ^ e ^ a
        t = c << 5 | c >>> 27
        b = t + f + b - 899497514 + blocks[j + 3] << 0
        d = d << 30 | d >>> 2
        f = c ^ d ^ e
        t = b << 5 | b >>> 27
        a = t + f + a - 899497514 + blocks[j + 4] << 0
        c = c << 30 | c >>> 2
        j += 5
      h0 = h0 + a << 0
      h1 = h1 + b << 0
      h2 = h2 + c << 0
      h3 = h3 + d << 0
      h4 = h4 + e << 0
      unless !end
        break
    HEX_CHARS[h0 >> 28 & 0x0F] + HEX_CHARS[h0 >> 24 & 0x0F] + HEX_CHARS[h0 >> 20 & 0x0F] + HEX_CHARS[h0 >> 16 & 0x0F] + HEX_CHARS[h0 >> 12 & 0x0F] + HEX_CHARS[h0 >> 8 & 0x0F] + HEX_CHARS[h0 >> 4 & 0x0F] + HEX_CHARS[h0 & 0x0F] + HEX_CHARS[h1 >> 28 & 0x0F] + HEX_CHARS[h1 >> 24 & 0x0F] + HEX_CHARS[h1 >> 20 & 0x0F] + HEX_CHARS[h1 >> 16 & 0x0F] + HEX_CHARS[h1 >> 12 & 0x0F] + HEX_CHARS[h1 >> 8 & 0x0F] + HEX_CHARS[h1 >> 4 & 0x0F] + HEX_CHARS[h1 & 0x0F] + HEX_CHARS[h2 >> 28 & 0x0F] + HEX_CHARS[h2 >> 24 & 0x0F] + HEX_CHARS[h2 >> 20 & 0x0F] + HEX_CHARS[h2 >> 16 & 0x0F] + HEX_CHARS[h2 >> 12 & 0x0F] + HEX_CHARS[h2 >> 8 & 0x0F] + HEX_CHARS[h2 >> 4 & 0x0F] + HEX_CHARS[h2 & 0x0F] + HEX_CHARS[h3 >> 28 & 0x0F] + HEX_CHARS[h3 >> 24 & 0x0F] + HEX_CHARS[h3 >> 20 & 0x0F] + HEX_CHARS[h3 >> 16 & 0x0F] + HEX_CHARS[h3 >> 12 & 0x0F] + HEX_CHARS[h3 >> 8 & 0x0F] + HEX_CHARS[h3 >> 4 & 0x0F] + HEX_CHARS[h3 & 0x0F] + HEX_CHARS[h4 >> 28 & 0x0F] + HEX_CHARS[h4 >> 24 & 0x0F] + HEX_CHARS[h4 >> 20 & 0x0F] + HEX_CHARS[h4 >> 16 & 0x0F] + HEX_CHARS[h4 >> 12 & 0x0F] + HEX_CHARS[h4 >> 8 & 0x0F] + HEX_CHARS[h4 >> 4 & 0x0F] + HEX_CHARS[h4 & 0x0F]

