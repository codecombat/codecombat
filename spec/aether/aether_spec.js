/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const Aether = require('../aether');

describe("Aether", function() {
  describe("Basic tests", function() {
    it("doesn't immediately break", function() {
      const aether = new Aether();
      const code = "var x = 3;";
      return expect(aether.canTranspile(code)).toEqual(true);
    });

    it("running functions isn't broken horribly", function() {
      const aether = new Aether();
      const code = "return 1000;";
      aether.transpile(code);
      return expect(aether.run()).toEqual(1000);
    });

    return it('can run an empty function', function() {
      const aether = new Aether();
      aether.transpile('');
      expect(aether.run()).toEqual(undefined);
      return expect(aether.problems.errors).toEqual([]);
  });
});

  describe("Transpile heuristics", function() {
    let aether = null;
    beforeEach(() => aether = new Aether());
    return it("Compiles a blank piece of code", function() {
      const raw = "";
      return expect(aether.canTranspile(raw)).toEqual(true);
    });
  });

  describe("Defining functions", function() {
    const aether = new Aether();
    return it("should be able to define functions in functions", function() {
      const code = `\
function fib(n) {
  return n < 2 ? n : fib(n - 1) + fib(n - 2);
}

var chupacabra = fib(6)
return chupacabra;\
`;
      aether.transpile(code);
      const fn = aether.createFunction();
      return expect(fn()).toEqual(8);
    });
  });

  return describe("Changing Language", function() {
    const aether = new Aether();
    it("should change the language if valid", () => expect(aether.setLanguage("coffeescript")).toEqual("coffeescript"));

    return it("should not allow non-supported languages", () => expect(aether.setLanguage.bind(null, "Brainfuck")).toThrow());
  });
});


/*
var test1 = function test2(test3) {
    test1();
    test2();
    test3();
}
test4 = function(test5) {
    test4();
    test5();
}
*/
