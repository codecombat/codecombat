Aether = require '../aether'

describe "Flow test suite", ->
  describe "Basic flow", ->
    code = """
      var four = 2 * 2;  // three: 2, 2, four = 2 * 2
      this.say(four);  // one
    """
    nStatements = 4  # If we improved our statement detection, this might go up
    it "should count statements and track vars", ->
      thisValue = say: ->
      options =
        includeFlow: true
        includeMetrics: true
      aether = new Aether options
      aether.transpile(code)
      fn = aether.createMethod thisValue
      for i in [0 ... 4]
        if i
          expect(aether.flow.states.length).toEqual i
          expect(aether.flow.states[i - 1].statementsExecuted).toEqual nStatements
          expect(aether.metrics.callsExecuted).toEqual i
          expect(aether.metrics.statementsExecuted).toEqual i * nStatements
        fn()
      last = aether.flow.states[3].statements
      expect(last[0].variables.four).not.toEqual "4"
      expect(last[last.length - 1].variables.four).toEqual "4"  # could change if we serialize differently

    it "should obey includeFlow", ->
      thisValue = say: ->
      options =
        includeFlow: false
        includeMetrics: true
      aether = new Aether options
      aether.transpile(code)
      fn = aether.createMethod thisValue
      fn()
      expect(aether.flow.states).toBe undefined
      expect(aether.metrics.callsExecuted).toEqual 1
      expect(aether.metrics.statementsExecuted).toEqual nStatements

    it "should obey includeMetrics", ->
      thisValue = say: ->
      options =
        includeFlow: true
        includeMetrics: false
      aether = new Aether options
      aether.transpile(code)
      fn = aether.createMethod thisValue
      fn()
      expect(aether.flow.states.length).toEqual 1
      expect(aether.flow.states[0].statementsExecuted).toEqual nStatements
      expect(aether.metrics.callsExecuted).toBe undefined
      expect(aether.metrics.statementsExecuted).toBe undefined

    it "should not log statements when not needed", ->
      thisValue = say: ->
      options =
        includeFlow: false
        includeMetrics: false
      aether = new Aether options
      pure = aether.transpile(code)
      expect(pure.search /log(Statement|Call)/).toEqual -1
      expect(pure.search /_aetherUserInfo/).toEqual -1
      expect(pure.search /_aether\.vars/).toEqual -1
