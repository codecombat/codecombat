Problem = require 'views/play/level/tome/Problem'

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

  # TODO: Problems are no longer saved when creating Problems; instead it's in SpellView. Update tests?
  xit 'save user code problem', ->
    new Problem aether, aetherProblem, ace, false, true, levelID
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
    new Problem aether, aetherProblem, ace, false, true, levelID
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

    new Problem aether, aetherProblem, ace, false, true, levelID
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
