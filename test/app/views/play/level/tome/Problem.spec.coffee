Problem = require 'views/play/level/tome/Problem'
locale = require 'locale/locale'
locale.storeLoadedLanguage('rot13', require('locale/rot13')) # Normally locale.load does this for us

describe 'Problem', ->
  # boilerplate problem params
  ace = {
    getSession: -> {
      getDocument: -> {
        createAnchor: ->
      }
      addMarker: ->
    }
  }
  aether = {
    raw: "this.say('hi');\nthis.sad('bye');"
    language: { id: 'javascript' }
  }
  aetherProblem = {
    hint: 'did you mean say instead of sad?'
    id: 'unknown_ReferenceError'
    level: 'error'
    message: 'Line 1: tmp2[tmp3] is not a function'
    range: [
      { row: 1 }
      { row: 1 }
    ]
    type: 'runtime'
  }
  levelID = 'awesome'
  
  describe '.translate()', ->
    beforeEach ->
      @oldLang = $.i18n.lng()
      $.i18n.setLng('rot13')
    afterEach ->
      $.i18n.setLng(@oldLang)
    it 'translates messages with line numbers, error types, and placeholders', ->
      english = 'Line 12: ReferenceError: somethin is not defined'
      rot13 = 'Yvar 12: ErsreraprReebe: somethin vf abg qrsvarq'
      expect(Problem.prototype.translate(english)).toEqual(rot13)
      english = "`foo`'s argument `bar` has a problem. Is there an enemy within your line-of-sight yet?"
      rot13 = "`foo`'f nethzrag `bar` unf n ceboyrz. Vf gurer na rarzl jvguva lbhe yvar-bs-fvtug lrg?"
      expect(Problem.prototype.translate(english)).toEqual(rot13)
      english="""
        `attack`'s argument `target` should have type `unit`, but got `function`.
        Target a unit.
      """
      rot13="""
        `attack`'f nethzrag `target` fubhyq unir glcr `unit`, ohg tbg `function`.
        Gnetrg n havg.
      """
      expect(Problem.prototype.translate(english)).toEqual(rot13)

  # TODO: Problems are no longer saved when creating Problems; instead it's in SpellView. Update tests?
  xit 'save user code problem', ->
    new Problem {aether, aetherProblem, ace, isCast: false, levelID}
    expect(jasmine.Ajax.requests.count()).toBe(1)

    request = jasmine.Ajax.requests.mostRecent()
    expect(request.url).toEqual("/db/user.code.problem")

    params = JSON.parse(request.params)
    expect(params.code).toEqual(aether.raw)
    expect(params.codeSnippet).toEqual("this.sad('bye');")
    expect(params.errHint).toEqual(aetherProblem.hint)
    expect(params.errId).toEqual(aetherProblem.id)
    expect(params.errLevel).toEqual(aetherProblem.level)
    expect(params.errMessage).toEqual(aetherProblem.message)
    expect(params.errRange).toEqual(aetherProblem.range)
    expect(params.errType).toEqual(aetherProblem.type)
    expect(params.language).toEqual(aether.language.id)
    expect(params.levelID).toEqual(levelID)

  xit 'save user code problem no range', ->
    aetherProblem.range = null
    new Problem {aether, aetherProblem, ace, isCast: false, levelID}
    expect(jasmine.Ajax.requests.count()).toBe(1)

    request = jasmine.Ajax.requests.mostRecent()
    expect(request.url).toEqual("/db/user.code.problem")

    params = JSON.parse(request.params)
    expect(params.code).toEqual(aether.raw)
    expect(params.errHint).toEqual(aetherProblem.hint)
    expect(params.errId).toEqual(aetherProblem.id)
    expect(params.errLevel).toEqual(aetherProblem.level)
    expect(params.errMessage).toEqual(aetherProblem.message)
    expect(params.errType).toEqual(aetherProblem.type)
    expect(params.language).toEqual(aether.language.id)
    expect(params.levelID).toEqual(levelID)

    # Difference when no range
    expect(params.codeSnippet).toBeUndefined()
    expect(params.errRange).toBeUndefined()

  xit 'save user code problem multi-line snippet', ->
    aether.raw = "this.say('hi');\nthis.sad\n('bye');"
    aetherProblem.range = [ { row: 1 }, { row: 2 } ]

    new Problem {aether, aetherProblem, ace, isCast: false, levelID}
    expect(jasmine.Ajax.requests.count()).toBe(1)

    request = jasmine.Ajax.requests.mostRecent()
    expect(request.url).toEqual("/db/user.code.problem")

    params = JSON.parse(request.params)
    expect(params.code).toEqual(aether.raw)
    expect(params.codeSnippet).toEqual("this.sad\n('bye');")
    expect(params.errHint).toEqual(aetherProblem.hint)
    expect(params.errId).toEqual(aetherProblem.id)
    expect(params.errLevel).toEqual(aetherProblem.level)
    expect(params.errMessage).toEqual(aetherProblem.message)
    expect(params.errRange).toEqual(aetherProblem.range)
    expect(params.errType).toEqual(aetherProblem.type)
    expect(params.language).toEqual(aether.language.id)
    expect(params.levelID).toEqual(levelID)
