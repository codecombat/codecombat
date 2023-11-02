Aether = require '../aether'

describe "Aether", ->
  describe "Basic tests", ->
    it "doesn't immediately break", ->
      aether = new Aether()
      code = "var x = 3;"
      expect(aether.canTranspile(code)).toEqual true

    it "running functions isn't broken horribly", ->
      aether = new Aether()
      code = "return 1000;"
      aether.transpile(code)
      expect(aether.run()).toEqual 1000

    it 'can run an empty function', ->
      aether = new Aether()
      aether.transpile ''
      expect(aether.run()).toEqual undefined
      expect(aether.problems.errors).toEqual []

  describe "Transpile heuristics", ->
    aether = null
    beforeEach ->
      aether = new Aether()
    it "Compiles a blank piece of code", ->
      raw = ""
      expect(aether.canTranspile(raw)).toEqual true

  describe "Defining functions", ->
    aether = new Aether()
    it "should be able to define functions in functions", ->
      code = """
        function fib(n) {
          return n < 2 ? n : fib(n - 1) + fib(n - 2);
        }

        var chupacabra = fib(6)
        return chupacabra;
      """
      aether.transpile(code)
      fn = aether.createFunction()
      expect(fn()).toEqual 8

  describe "Changing Language", ->
    aether = new Aether()
    it "should change the language if valid", ->
      expect(aether.setLanguage "coffeescript").toEqual "coffeescript"

    it "should not allow non-supported languages", ->
      expect(aether.setLanguage.bind null, "Brainfuck").toThrow()


###
var test1 = function test2(test3) {
    test1();
    test2();
    test3();
}
test4 = function(test5) {
    test4();
    test5();
}
###
