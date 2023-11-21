Aether = require '../aether'

describe "Problem Test Suite", ->
  describe "Transpile problems", ->
    it "pass through python syntax info", ->
      code = """
      self.attack('Brak)
      """
      aether = new Aether language: 'python'
      aether.transpile code
      console.log(aether.problems.errors[0])
      expect(aether.problems.errors.length).toEqual(1)
      expect(aether.problems.errors[0].extra.kind).toBe("CLASSIFY")
