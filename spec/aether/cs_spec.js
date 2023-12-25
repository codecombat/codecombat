/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const Aether = require('../aether');

describe("CS test Suite!", function() {
  describe("CS compilation", function() {
    const aether = new Aether({language: "coffeescript"});
    return it("Should compile functions", function() {
      const code = `\
return 1000\
`;
      aether.transpile(code);
      expect(aether.run()).toEqual(1000);
      return expect(aether.problems.errors).toEqual([]);
  });
});

  describe("CS compilation with lang set after contruction", function() {
    const aether = new Aether();
    return it("Should compile functions", function() {
      const code = `\
return 2000 if false
return 1000\
`;
      aether.setLanguage("coffeescript");
      aether.transpile(code);
      expect(aether.canTranspile(code)).toEqual(true);
      return expect(aether.problems.errors).toEqual([]);
  });
});

  describe("CS Test Spec #1", function() {
    const aether = new Aether({language: "coffeescript"});
    return it("mathmetics order", function() {
      const code = `\
return (2*2 + 2/2 - 2*2/2)\
`;
      aether.transpile(code);
      expect(aether.run()).toEqual(3);
      return expect(aether.problems.errors).toEqual([]);
  });
});

  describe("CS Test Spec #2", function() {
    const aether = new Aether({language: "coffeescript"});
    return it("function call", function() {
      const code = `\
fib = (n) ->
  (if n < 2 then n else fib(n - 1) + fib(n - 2))
chupacabra = fib(6)\
`;
      aether.transpile(code);
      const fn = aether.createFunction();
      expect(aether.canTranspile(code)).toEqual(true);
      expect(aether.run()).toEqual(8); // fail
      return expect(aether.problems.errors).toEqual([]);
  });
});

  describe("Basics", function() {
    const aether = new Aether({language: "coffeescript"});
    it("Simple For", function() {
      const code = `\
count = 0
count++ for num in [1..10]
return count\
`;
      aether.transpile(code);
      expect(aether.canTranspile(code)).toEqual(true);
      expect(aether.run()).toEqual(10);
      return expect(aether.problems.errors).toEqual([]);
  });

    it("Simple While", function() {
      const code = `\
count = 0
count++ until count is 100
return count\
`;
      aether.transpile(code);
      expect(aether.canTranspile(code)).toEqual(true);
      expect(aether.run()).toEqual(100);
      return expect(aether.problems.errors).toEqual([]);
  });

    it("Should Map", function() {
      // See: https://github.com/codecombat/aether/issues/97
      const code = "return (num for num in [10..1])";

      aether.transpile(code);
      expect(aether.canTranspile(code)).toEqual(true);
      expect(aether.run()).toEqual([10, 9, 8, 7, 6, 5, 4, 3, 2, 1]);
      return expect(aether.problems.errors).toEqual([]);
  });

    it("Should Map properties", function() {
      const code = `\
yearsOld = max: 10, ida: 9, tim: 11
ages = for child, age of yearsOld
  "#{child} is #{age}"
return ages\
`;
      aether.transpile(code);
      expect(aether.canTranspile(code)).toEqual(true);
      expect(aether.run()).toEqual(["max is 10", "ida is 9", "tim is 11"]);
      return expect(aether.problems.errors).toEqual([]);
  });

    it("Should compile empty function", function() {
      const code = `\
func = () ->
return typeof func\
`;
      aether.transpile(code);
      expect(aether.canTranspile(code)).toEqual(true);
      expect(aether.run()).toEqual('function');
      return expect(aether.problems.errors).toEqual([]);
  });

    it("Should compile objects", function() {
      const code = `\
singers = {Jagger: 'Rock', Elvis: 'Roll'}
return singers\
`;
      aether.transpile(code);
      expect(aether.canTranspile(code)).toEqual(true);
      expect(aether.run()).toEqual(({Jagger: 'Rock', Elvis: 'Roll'}));
      return expect(aether.problems.errors).toEqual([]);
  });

    it("Should compile classes", function() {
      const code = `\
class MyClass
  test: ->
    return 1000
myClass = new MyClass()
return myClass.test()\
`;
      aether.transpile(code);
      expect(aether.canTranspile(code)).toEqual(true);
      expect(aether.run()).toEqual(1000);
      return expect(aether.problems.errors).toEqual([]);
  });

    xit("Should compile super", function() {
      // super is not supported in CSR yet: https://github.com/michaelficarra/CoffeeScriptRedux/search?q=super&ref=cmdform&type=Issues
      const code = `\
class Animal
  constructor: (@name) ->
  move: (meters) ->
    @name + " moved " + meters + "m."
class Snake extends Animal
  move: ->
    super 5
sam = new Snake "Sammy the Python"
sam.move()\
`;
      aether.transpile(code);
      expect(aether.run()).toEqual("Sammy the Python moved 5m.");
      return expect(aether.problems.errors).toEqual([]);
  });

    it("Should compile string interpolation", function() {
      const code = `\
meters = 5
"Sammy the Python moved #{meters}m."\
`;
      aether.transpile(code);
      expect(aether.run()).toEqual("Sammy the Python moved 5m.");
      return expect(aether.problems.errors).toEqual([]);
  });

    return it("Should implicitly return the last statement", function() {
      aether.transpile('"hi"');
      expect(aether.run()).toEqual('hi');
      return expect(aether.problems.errors).toEqual([]);
  });
});

  return describe("Errors", function() {
    const aether = new Aether({language: "coffeescript"});

    it("Bad indent", function() {
      const code = `\
fn = ->
  x = 45
    x += 5
  return x
return fn()\
`;
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(1);
      // TODO: No range information for this error
      // https://github.com/codecombat/aether/issues/114
      return expect(aether.problems.errors[0].message.indexOf("Syntax error on line 5, column 10: unexpected '+'")).toBe(0);
    });

    it("Transpile error, missing )", function() {
      const code = `\
fn = ->
  return 45
x = fn(
return x\
`;
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(1);
      // TODO: No range information for this error
      // https://github.com/codecombat/aether/issues/114
      return expect(aether.problems.errors[0].message.indexOf("Unexpected DEDENT")).toBe(0);
    });

    xit("Missing @: x() row 0", function() {
      // TODO: error ranges incorrect
      // https://github.com/codecombat/aether/issues/153
      const code = "x()";
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(1);
      expect(aether.problems.errors[0].message).toEqual("Missing `@` keyword; should be `@x`.");
      return expect(aether.problems.errors[0].range).toEqual([ { ofs: 0, row: 0, col: 0 }, { ofs: 3, row: 0, col: 3 } ]);
    });

    it("Missing @: x() row 1", function() {
      const code = `\
y = 5
x()\
`;
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(1);
      return expect(aether.problems.errors[0].message).toEqual("Missing `@` keyword; should be `@x`.");
    });
      // https://github.com/codecombat/aether/issues/115
      // expect(aether.problems.errors[0].range).toEqual([ { ofs: 6, row: 1, col: 0 }, { ofs: 9, row: 1, col: 3 } ])

    it("Missing @: x() row 3", function() {
      const code = `\
y = 5
s = 'some other stuff'
if y is 5
  x()\
`;
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(1);
      return expect(aether.problems.errors[0].message).toEqual("Missing `@` keyword; should be `@x`.");
    });
      // https://github.com/codecombat/aether/issues/115
      // expect(aether.problems.errors[0].range).toEqual([ { ofs: 42, row: 3, col: 2 }, { ofs: 45, row: 3, col: 5 } ])

    xit("@getItems missing parentheses", function() {
      // https://github.com/codecombat/aether/issues/111
      const history = [];
      const getItems = () => [{'pos':1}, {'pos':4}, {'pos':3}, {'pos':5}];
      const move = i => history.push(i);
      const thisValue = {getItems, move};
      const code = `\
@getItems\
`;
      aether.transpile(code);
      const method = aether.createMethod(thisValue);
      aether.run(method);
      expect(aether.problems.errors.length).toEqual(1);
      expect(aether.problems.errors[0].message).toEqual('@getItems has no effect.');
      expect(aether.problems.errors[0].hint).toEqual('Is it a method? Those need parentheses: @getItems()');
      return expect(aether.problems.errors[0].range).toEqual([ { ofs : 0, row : 0, col : 0 }, { ofs : 10, row : 0, col : 10 } ]);
    });

    xit("@getItems missing parentheses row 1", function() {
      // https://github.com/codecombat/aether/issues/110
      const history = [];
      const getItems = () => [{'pos':1}, {'pos':4}, {'pos':3}, {'pos':5}];
      const move = i => history.push(i);
      const thisValue = {getItems, move};
      const code = `\
x = 5
@getItems
y = 6\
`;
      aether.transpile(code);
      const method = aether.createMethod(thisValue);
      aether.run(method);
      expect(aether.problems.errors.length).toEqual(1);
      expect(aether.problems.errors[0].message).toEqual('@getItems has no effect.');
      expect(aether.problems.errors[0].hint).toEqual('Is it a method? Those need parentheses: @getItems()');
      return expect(aether.problems.errors[0].range).toEqual([ { ofs : 7, row : 1, col : 0 }, { ofs : 16, row : 1, col : 9 } ]);
    });

    it("Incomplete string", function() {
      const code = `\
s = 'hi
return s\
`;
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(1);
      return expect(aether.problems.errors[0].message).toEqual("Unclosed \"'\" at EOF");
    });
      // https://github.com/codecombat/aether/issues/114
      // expect(aether.problems.errors[0].range).toEqual([ { ofs : 4, row : 0, col : 4 }, { ofs : 7, row : 0, col : 7 } ])

    return xit("Runtime ReferenceError", function() {
      // TODO: error ranges incorrect
      // https://github.com/codecombat/aether/issues/153
      const code = `\
x = 5
y = x + z\
`;
      aether.transpile(code);
      aether.run();
      expect(aether.problems.errors.length).toEqual(1);
      expect(/ReferenceError/.test(aether.problems.errors[0].message)).toBe(true);
      return expect(aether.problems.errors[0].range).toEqual([ { ofs : 14, row : 1, col : 8 }, { ofs : 15, row : 1, col : 9 } ]);
    });
  });
});
