/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const Aether = require('../aether');

describe("Problem Test Suite", function() {
  describe("Transpile problems", function() {
    it("missing a closing quote: self.attack('Brak)", function() {
      const code = `\
self.attack('Brak)\
`;
      const aether = new Aether({language: 'python'});
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(1);
      expect(aether.problems.errors[0].type).toEqual('transpile');
      expect(aether.problems.errors[0].message).toEqual("Unterminated string constant");
      return expect(aether.problems.errors[0].hint).toEqual("Missing a quotation mark. Try `'Brak'`");
    });

    it("missing a closing quote: s = \"hi", function() {
      const code = `\
s = "hi\
`;
      const aether = new Aether({language: 'python'});
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(1);
      expect(aether.problems.errors[0].type).toEqual('transpile');
      expect(aether.problems.errors[0].message).toEqual("Unterminated string constant");
      return expect(aether.problems.errors[0].hint).toEqual("Missing a quotation mark. Try `\"hi\"`");
    });

    it("missing a closing quote: '", function() {
      const code = `\
'\
`;
      const aether = new Aether({language: 'python'});
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(1);
      expect(aether.problems.errors[0].type).toEqual('transpile');
      expect(aether.problems.errors[0].message).toEqual("Unterminated string constant");
      return expect(aether.problems.errors[0].hint).toEqual("Missing a quotation mark. Try `''`");
    });

    it("Unexpected indent", function() {
      const code = `\
x = 5
  y = 7\
`;
      const aether = new Aether({language: 'python'});
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(1);
      expect(aether.problems.errors[0].type).toEqual('transpile');
      expect(aether.problems.errors[0].message).toEqual("Unexpected indent");
      return expect(aether.problems.errors[0].hint).toEqual("Code needs to line up.");
    });

    xit("missing a closing quote: s = \"hi", function() {
      // https://github.com/codecombat/aether/issues/113
      const code = `\
var s = "hi\
`;
      const aether = new Aether;
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(3);
      expect(aether.problems.errors[0].type).toEqual('transpile');
      expect(aether.problems.errors[0].message).toEqual("Unclosed string.");
      return expect(aether.problems.errors[0].hint).toEqual("You may be missing a closing quotation mark. Try `\"hi\"`");
    });

    it("Unexpected token 'self move'", function() {
      const code = `\
self move\
`;
      const problemContext = {thisMethods: [ 'moveUp']};
      const aether = new Aether({language: "python", problemContext});
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(1);
      expect(aether.problems.errors[0].type).toEqual('transpile');
      expect(aether.problems.errors[0].message).toEqual("Unexpected token");
      return expect(aether.problems.errors[0].hint).toEqual("Try `hero.moveUp()`");
    });

    it("Unexpected token 'self self.move'", function() {
      const code = `\
self self.move\
`;
      const problemContext = {thisMethods: [ 'moveUp']};
      const aether = new Aether({language: "python", problemContext});
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(2);
      expect(aether.problems.errors[0].type).toEqual('transpile');
      expect(aether.problems.errors[0].message).toEqual("Unexpected token");
      return expect(aether.problems.errors[0].hint).toEqual("Delete extra `self`");
    });

    it("Unexpected token 'self.moveUp())'", function() {
      const code = `\
self.moveUp())\
`;
      const problemContext = {thisMethods: [ 'moveUp']};
      const aether = new Aether({language: "python", problemContext});
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(1);
      expect(aether.problems.errors[0].type).toEqual('transpile');
      expect(aether.problems.errors[0].message).toEqual("Unexpected token");
      return expect(aether.problems.errors[0].hint).toEqual("Delete extra `)`");
    });

    it("Unexpected token 'self.moveUp()self.moveDown()'", function() {
      const code = `\
self.moveUp()self.moveDown()\
`;
      const problemContext = {thisMethods: [ 'moveUp', 'moveDown']};
      const aether = new Aether({language: "python", problemContext});
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(1);
      expect(aether.problems.errors[0].type).toEqual('transpile');
      expect(aether.problems.errors[0].message).toEqual("Unexpected token");
      return expect(aether.problems.errors[0].hint).toEqual("Put each command on a separate line");
    });

    it("Capitalized loop", function() {
      const code = `\
Loop:
  x = 5\
`;
      const problemContext = {thisMethods: [ 'moveUp', 'moveDown']};
      const aether = new Aether({language: "python", problemContext, simpleLoops: true});
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(1);
      expect(aether.problems.errors[0].type).toEqual('transpile');
      expect(aether.problems.errors[0].message).toEqual("Unexpected token");
      return expect(aether.problems.errors[0].hint).toEqual("Should be lowercase. Try `loop`");
    });

    it("Double var", function() {
      const code = `\
var enemy = 'Bob';
var enemy = 'Sue';\
`;
      const aether = new Aether();
      aether.transpile(code);
      expect(aether.problems.warnings.length).toEqual(1);
      expect(aether.problems.warnings[0].type).toEqual('transpile');
      expect(aether.problems.warnings[0].message).toEqual("'enemy' is already defined.");
      return expect(aether.problems.warnings[0].hint).toEqual("Don't use the 'var' keyword for 'enemy' the second time.");
    });

    it("if without :", function() {
      const code = `\
if True
  x = 5\
`;
      const problemContext = {thisMethods: [ 'moveUp', 'moveDown']};
      const aether = new Aether({language: "python", problemContext});
      aether.transpile(code);
      console.log(aether.problems.errors[0]);
      expect(aether.problems.errors.length).toEqual(1);
      expect(aether.problems.errors[0].type).toEqual('transpile');
      expect(aether.problems.errors[0].message).toEqual("Unexpected token");
      return expect(aether.problems.errors[0].hint).toEqual("You are missing a `:` on the end of the line following `if True`");
    });

    it("indented if without :", function() {
      const code = `\
if True:
  if True
    x = 5\
`;
      const problemContext = {thisMethods: [ 'moveUp', 'moveDown']};
      const aether = new Aether({language: "python", problemContext});
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(1);
      expect(aether.problems.errors[0].type).toEqual('transpile');
      expect(aether.problems.errors[0].message).toEqual("Unexpected token");
      return expect(aether.problems.errors[0].hint).toEqual("You are missing a ':' after '  if True'. Try `  if True:`");
    });

    it("if without test clause", function() {
      const code = `\
if :
  x = 5\
`;
      const problemContext = {thisMethods: [ 'moveUp', 'moveDown']};
      const aether = new Aether({language: "python", problemContext});
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(1);
      expect(aether.problems.errors[0].type).toEqual('transpile');
      expect(aether.problems.errors[0].message).toEqual("Unexpected token");
      return expect(aether.problems.errors[0].hint).toEqual("Your if statement is missing a test clause. Try `if True:`");
    });

    it("else without : #1", function() {
      const code = `\
if False:
  x = 5
else
  x = 7\
`;
      const problemContext = {thisMethods: [ 'moveUp', 'moveDown']};
      const aether = new Aether({language: "python", problemContext});
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(1);
      expect(aether.problems.errors[0].type).toEqual('transpile');
      expect(aether.problems.errors[0].message).toEqual("Unexpected indent");
      return expect(aether.problems.errors[0].hint).toEqual("You are missing a ':' after 'else'. Try `else:`");
    });

    xit("else without : #2", function() {
      // https://github.com/differentmatt/filbert/issues/44
      const code = `\
if False:
  x = 5
else
x = 7\
`;
      const problemContext = {thisMethods: [ 'moveUp', 'moveDown']};
      const aether = new Aether({language: "python", problemContext});
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(1);
      expect(aether.problems.errors[0].type).toEqual('transpile');
      expect(aether.problems.errors[0].message).toEqual("Unexpected indent");
      return expect(aether.problems.errors[0].hint).toEqual("You are missing a ':' after 'else'. Try `else:`");
    });

    xit("else without : #3", function() {
      // https://github.com/differentmatt/filbert/issues/44
      const code = `\
if False:
  x = 5
else x = 7\
`;
      const problemContext = {thisMethods: [ 'moveUp', 'moveDown']};
      const aether = new Aether({language: "python", problemContext});
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(1);
      expect(aether.problems.errors[0].type).toEqual('transpile');
      expect(aether.problems.errors[0].message).toEqual("Unexpected indent");
      return expect(aether.problems.errors[0].hint).toEqual("You are missing a ':' after 'else'. Try `else:`");
    });

    it("else without : #4", function() {
      const code = `\
if True:
  if False:
    x = 7
  else
    x = 59\
`;
      const problemContext = {thisMethods: [ 'moveUp', 'moveDown']};
      const aether = new Aether({language: "python", problemContext});
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(1);
      expect(aether.problems.errors[0].type).toEqual('transpile');
      expect(aether.problems.errors[0].message).toEqual("Unexpected indent");
      return expect(aether.problems.errors[0].hint).toEqual("You are missing a ':' after 'else'. Try `else:`");
    });

    it("self.moveRight(", function() {
      const code = `\
self.moveRight(\
`;
      const problemContext = {};
      const aether = new Aether({language: "python", problemContext});
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(1);
      expect(aether.problems.errors[0].type).toEqual('transpile');
      expect(aether.problems.errors[0].message).toEqual("Unexpected token");
      return expect(aether.problems.errors[0].hint).toEqual("Unmatched `(`.  Every opening `(` needs a closing `)` to match it.");
    });

    return it("self.moveRight(()", function() {
      const code = `\
self.moveRight(()\
`;
      const problemContext = {};
      const aether = new Aether({language: "python", problemContext});
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(1);
      expect(aether.problems.errors[0].type).toEqual('transpile');
      expect(aether.problems.errors[0].message).toEqual("Unexpected token");
      return expect(aether.problems.errors[0].hint).toEqual("Unmatched `(`.  Every opening `(` needs a closing `)` to match it.");
    });
  });

  describe("Runtime problems", function() {
    it("Should capture runtime problems", function() {
      // 0123456789012345678901234567
      const code = `\
var methodName = 'explode';
this[methodName]();\
`;
      const options = {
        thisValue: {},
        problems: {jshint_W040: {level: "ignore"}}
      };
      const aether = new Aether(options);
      aether.transpile(code);
      aether.run();
      expect(aether.problems.errors.length).toEqual(1);
      const problem = aether.problems.errors[0];
      expect(problem.type).toEqual('runtime');
      expect(problem.level).toEqual('error');
      expect(problem.message).toMatch(/has no method/);
      expect(problem.range != null ? problem.range.length : undefined).toEqual(2);
      const [start, end] = Array.from(problem.range);
      expect(start.ofs).toEqual(28);
      expect(start.row).toEqual(1);
      expect(start.col).toEqual(0);
      expect(end.ofs).toEqual(46);
      expect(end.row).toEqual(1);
      expect(end.col).toEqual(18);
      return expect(problem.message).toMatch(/Line 2/);
    });

    it("Shouldn't die on invalid crazy code", function() {
      const code = `\
if (true >== true){
  true;}\
`;
      const aether = new Aether({});
      aether.transpile(code);
      aether.run();
      expect(aether.problems.errors.length).toBeGreaterThan(0);
      const problem = aether.problems.errors[0];
      expect(problem.type).toEqual('transpile');
      return expect(problem.level).toEqual('error');
    });

    it("Shouldn't die on more invalid crazy code", function() {
      const code = `\
var coins = {'emerald': []};
coins.'emerald'.push({type: 'emerald', bountyGold: 5});\
`;
      const aether = new Aether({});
      expect(() => aether.transpile(code)).not.toThrow();
      aether.run();
      expect(aether.problems.errors.length).toBeGreaterThan(0);
      const problem = aether.problems.errors[0];
      expect(problem.type).toEqual('transpile');
      return expect(problem.level).toEqual('error');
    });

    it("Should hard-cap execution to break infinite loops.", function() {
      const code = `\
while(true) {
  ;
}\
`;
      const aether = new Aether({executionLimit: 9001});
      aether.transpile(code);
      aether.run();
      expect(aether.problems.errors.length).toBeGreaterThan(0);
      const problem = aether.problems.errors[0];
      expect(problem.type).toEqual('runtime');
      return expect(problem.level).toEqual('error');
    });

    it("Should hard-cap execution after a certain limit.", function() {
      const code = `\
for (var i = 0; i < 1000; ++i) {}
return 'mojambo';\
`;
      const aether = new Aether({executionLimit: 500});
      aether.transpile(code);
      return expect(aether.run()).toBeUndefined();
    });

    it("Shouldn't hard-cap execution too early.", function() {
      const code = `\
for (var i = 0; i < 1000; ++i) {}
return 'mojambo';\
`;
      const aether = new Aether({executionLimit: 9001});
      aether.transpile(code);
      return expect(aether.run()).toEqual('mojambo');
    });

    it("Should error on undefined property accesses.", function() {
      const code = `\
var bar = 'bar';
var foobar = foo + bar;
return foobar;\
`;
      const aether = new Aether({functionName: 'foobarFactory'});
      aether.transpile(code);
      expect(aether.run()).not.toEqual('undefinedbar');
      expect(aether.run()).toEqual(undefined);
      return expect(aether.problems.errors).not.toEqual([]);
  });

    return it("Access prop on null", function() {
      const code = `\
def findFlag():
  return None
flag = findFlag()
x = flag.pos
return x\
`;
      const problemContext = {};
      const aether = new Aether({language: "python", problemContext});
      aether.transpile(code);
      expect(aether.run()).toEqual(null);
      expect(aether.problems.errors).not.toEqual([]);
      expect(aether.problems.errors.length).toEqual(1);
      expect(aether.problems.errors[0].type).toEqual('runtime');
      expect(aether.problems.errors[0].message).toEqual("Line 4: Cannot read property 'pos' of null");
      return expect(aether.problems.errors[0].hint).toEqual("'flag' was null. Use a null check before accessing properties. Try `if flag:`");
    });
  });

  return describe("problemContext", function() {
    // NOTE: the problemContext tests are roughly in the order they're checked in the code

    describe("General", function() {

      it("Call non-this undefined function x()", function() {
        const history = [];
        const log = s => history.push(s);
        const attack = () => history.push('attack');
        const selfValue = {say: log, attack};
        const code = "x()";
        const problemContext = {thisMethods: [ 'log', 'attack' ]};
        const aether = new Aether({language: "python", problemContext});
        aether.transpile(code);
        const method = aether.createMethod(selfValue);
        aether.run(method);
        expect(aether.problems.errors.length).toEqual(1);
        expect(aether.problems.errors[0].type).toEqual("runtime");
        expect(aether.problems.errors[0].message).toEqual("Line 1: ReferenceError: x is not defined");
        expect(aether.problems.errors[0].hint).toEqual("");
        return expect(aether.problems.errors[0].range).toEqual([ { ofs: 0, row: 0, col: 0 }, { ofs: 1, row: 0, col: 1 } ]);
      });

      return it("loop is not defined w/o simpleLoops", function() {
        const code = "loop";
        const aether = new Aether({language: "python"});
        aether.transpile(code);
        const method = aether.createMethod();
        aether.run();
        expect(aether.problems.errors.length).toEqual(1);
        expect(aether.problems.errors[0].type).toEqual("runtime");
        expect(aether.problems.errors[0].message).toEqual("Line 1: ReferenceError: loop is not defined");
        return expect(aether.problems.errors[0].hint).toEqual("");
      });
    });

    describe("No function", function() {

      it("Exact thisMethods", function() {
        const history = [];
        const log = s => history.push(s);
        const attack = () => history.push('attack');
        const selfValue = {say: log, attack};
        const code = `\
attack\
`;
        const problemContext = {thisMethods: [ 'log', 'attack' ]};
        const aether = new Aether({language: "python", problemContext});
        aether.transpile(code);
        const method = aether.createMethod(selfValue);
        aether.run(method);
        expect(aether.problems.errors.length).toEqual(1);
        expect(aether.problems.errors[0].message).toEqual("Line 1: ReferenceError: attack is not defined");
        return expect(aether.problems.errors[0].hint).toEqual("Try `hero.attack()`");
      });

      it("Case thisMethods", function() {
        const history = [];
        const log = s => history.push(s);
        const attack = () => history.push('attack');
        const selfValue = {say: log, attack};
        const code = `\
Attack\
`;
        const problemContext = {thisMethods: [ 'log', 'attack', 'tickle' ]};
        const aether = new Aether({language: "python", problemContext});
        aether.transpile(code);
        const method = aether.createMethod(selfValue);
        aether.run(method);
        expect(aether.problems.errors.length).toEqual(1);
        expect(aether.problems.errors[0].message).toEqual("Line 1: ReferenceError: Attack is not defined");
        return expect(aether.problems.errors[0].hint).toEqual("Try `hero.attack()`");
      });

      it("Exact commonThisMethods", function() {
        const selfValue = {};
        const code = `\
this.attack("Brak");\
`;
        const problemContext = {commonThisMethods: ['attack']};
        const aether = new Aether({problemContext});
        aether.transpile(code);
        const method = aether.createMethod(selfValue);
        aether.run(method);
        expect(aether.problems.errors.length).toEqual(1);
        expect(aether.problems.errors[0].message).toEqual("Line 1: Object #<Object> has no method 'attack'");
        return expect(aether.problems.errors[0].hint).toEqual("You do not have an item equipped with the attack skill.");
      });

      it("Exact commonThisMethods #2", function() {
        const selfValue = {};
        const code = `\
self.moveRight()\
`;
        const problemContext = {thisMethods: ['moveUp', 'moveLeft'], commonThisMethods: ['moveRight']};
        const aether = new Aether({problemContext, language: 'python'});
        aether.transpile(code);
        const method = aether.createMethod(selfValue);
        aether.run(method);
        expect(aether.problems.errors.length).toEqual(1);
        expect(aether.problems.errors[0].type).toEqual("runtime");
        expect(aether.problems.errors[0].message).toEqual("Line 1: Object #<Object> has no method 'moveRight'");
        return expect(aether.problems.errors[0].hint).toEqual("You do not have an item equipped with the moveRight skill.");
      });

      it("Case commonThisMethods", function() {
        const selfValue = {};
        const code = `\
self.moveup()\
`;
        const problemContext = {commonThisMethods: ['moveUp']};
        const aether = new Aether({language: 'python', problemContext});
        aether.transpile(code);
        const method = aether.createMethod(selfValue);
        aether.run(method);
        expect(aether.problems.errors.length).toEqual(1);
        expect(aether.problems.errors[0].message).toEqual("Line 1: Object #<Object> has no method 'moveup'");
        return expect(aether.problems.errors[0].hint).toEqual("Did you mean moveUp? You do not have an item equipped with that skill.");
      });

      it("Score commonThisMethods", function() {
        const selfValue = {};
        const code = `\
self.movright()\
`;
        const problemContext = {thisMethods: ['moveUp', 'moveLeft'], commonThisMethods: ['moveRight']};
        const aether = new Aether({problemContext, language: 'python'});
        aether.transpile(code);
        const method = aether.createMethod(selfValue);
        aether.run(method);
        expect(aether.problems.errors.length).toEqual(1);
        expect(aether.problems.errors[0].type).toEqual("runtime");
        expect(aether.problems.errors[0].message).toEqual("Line 1: Object #<Object> has no method 'movright'");
        return expect(aether.problems.errors[0].hint).toEqual("Did you mean moveRight? You do not have an item equipped with that skill.");
      });

      it("Score commonThisMethods #2", function() {
        const selfValue = {};
        const code = `\
this.movright()\
`;
        const problemContext = {thisMethods: ['moveUp', 'moveLeft'], commonThisMethods: ['moveRight']};
        const aether = new Aether({problemContext});
        aether.transpile(code);
        const method = aether.createMethod(selfValue);
        aether.run(method);
        expect(aether.problems.errors.length).toEqual(1);
        expect(aether.problems.errors[0].type).toEqual("runtime");
        expect(aether.problems.errors[0].message).toEqual("Line 1: Object #<Object> has no method 'movright'");
        return expect(aether.problems.errors[0].hint).toEqual("Did you mean moveRight? You do not have an item equipped with that skill.");
      });

      return it('enemy-ish variable is not defined', function() {
        const dude = { attack() {} };
        const problemContext = { thisMethods: ['findNearestEnemy'] };
    
        let aether = new Aether({ language: 'python', problemContext });
        aether.transpile('self.attack(enemy3)');
        aether.run(aether.createFunction().bind(dude));
        expect(aether.problems.errors[0].hint).toBe("There is no `enemy3`. Use `enemy3 = hero.findNearestEnemy()` first.");
    
        aether = new Aether({ language: 'javascript', problemContext });
        aether.transpile('this.attack(enemy3)');
        aether.run(aether.createFunction().bind(dude));
        return expect(aether.problems.errors[0].hint).toBe("There is no `enemy3`. Use `var enemy3 = hero.findNearestEnemy()` first.");
      });
    });
        
        
    describe("ReferenceError", function() {

      it("Exact stringReferences", function() {
        const history = [];
        const log = s => history.push(s);
        const attack = () => history.push('attack');
        const selfValue = {say: log, attack};
        const code = `\
self.attack(Brak)\
`;
        const problemContext = {stringReferences: ['Brak']};
        const aether = new Aether({language: "python", problemContext});
        aether.transpile(code);
        const method = aether.createMethod(selfValue);
        aether.run(method);
        expect(aether.problems.errors.length).toEqual(1);
        expect(aether.problems.errors[0].message).toEqual("Line 1: ReferenceError: Brak is not defined");
        return expect(aether.problems.errors[0].hint).toEqual("Missing quotes. Try `\"Brak\"`");
      });

      it("Exact thisMethods", function() {
        const selfValue = {};
        const code = `\
moveleft\
`;
        const problemContext = {thisMethods: ['moveRight', 'moveLeft', 'moveUp', 'moveDown']};
        const aether = new Aether({language: 'python', problemContext});
        aether.transpile(code);
        const method = aether.createMethod(selfValue);
        aether.run(method);
        expect(aether.problems.errors.length).toEqual(1);
        expect(aether.problems.errors[0].message).toEqual("Line 1: ReferenceError: moveleft is not defined");
        return expect(aether.problems.errors[0].hint).toEqual("Try `hero.moveLeft()`");
      });

      it("Exact thisMethods with range checks", function() {
        const history = [];
        const log = s => history.push(s);
        const attack = () => history.push('attack');
        const selfValue = {say: log, attack};
        const code = "attack()";
        const problemContext = {thisMethods: [ 'log', 'attack' ]};
        const aether = new Aether({language: "python", problemContext});
        aether.transpile(code);
        const method = aether.createMethod(selfValue);
        aether.run(method);
        expect(aether.problems.errors.length).toEqual(2);
        expect(aether.problems.errors[0].message).toEqual("Missing `self` keyword; should be `self.attack`.");
        expect(aether.problems.errors[0].range).toEqual([ { ofs: 0, row: 0, col: 0 }, { ofs: 8, row: 0, col: 8 } ]);
        expect(aether.problems.errors[1].message).toEqual("Line 1: ReferenceError: attack is not defined");
        return expect(aether.problems.errors[1].range).toEqual([ { ofs: 0, row: 0, col: 0 }, { ofs: 6, row: 0, col: 6 } ]);
      });

      it("Exact thisProperties", function() {
        const history = [];
        const log = s => history.push(s);
        const attack = () => history.push('attack');
        const selfValue = {say: log, attack};
        const code = `\
b = buildables\
`;
        const problemContext = {thisProperties: [ 'buildables' ]};
        const aether = new Aether({language: "python", problemContext});
        aether.transpile(code);
        const method = aether.createMethod(selfValue);
        aether.run(method);
        expect(aether.problems.errors.length).toEqual(1);
        expect(aether.problems.errors[0].message).toEqual("Line 1: ReferenceError: buildables is not defined");
        return expect(aether.problems.errors[0].hint).toEqual("Try `hero.buildables`");
      });

      it("Case this value", function() {
        const history = [];
        const log = s => history.push(s);
        const attack = () => history.push('attack');
        const selfValue = {say: log, moveRight: attack};
        const code = `\
sElf.moveRight()\
`;
        const problemContext = {thisMethods: ['moveRight']};
        const aether = new Aether({language: "python", problemContext});
        aether.transpile(code);
        const method = aether.createMethod(selfValue);
        aether.run(method);
        expect(aether.problems.errors.length).toEqual(1);
        expect(aether.problems.errors[0].message).toEqual("Line 1: ReferenceError: sElf is not defined");
        return expect(aether.problems.errors[0].hint).toEqual("Uppercase or lowercase problem. Try `self`");
      });

      it("Case stringReferences", function() {
        const history = [];
        const log = s => history.push(s);
        const attack = () => history.push('attack');
        const selfValue = {say: log, attack};
        const code = `\
self.attack(brak)\
`;
        const problemContext = {stringReferences: ['Bob', 'Brak', 'Zort']};
        const aether = new Aether({language: "python", problemContext});
        aether.transpile(code);
        const method = aether.createMethod(selfValue);
        aether.run(method);
        expect(aether.problems.errors.length).toEqual(1);
        expect(aether.problems.errors[0].message).toEqual("Line 1: ReferenceError: brak is not defined");
        return expect(aether.problems.errors[0].hint).toEqual("Missing quotes.  Try `\"Brak\"`");
      });

      it("Case thisMethods", function() {
        const selfValue = {};
        const code = `\
this.moveright();\
`;
        const problemContext = {thisMethods: ['moveUp', 'moveRight', 'moveLeft']};
        const aether = new Aether({problemContext});
        aether.transpile(code);
        const method = aether.createMethod(selfValue);
        aether.run(method);
        expect(aether.problems.errors.length).toEqual(1);
        expect(aether.problems.errors[0].type).toEqual("runtime");
        expect(aether.problems.errors[0].message).toEqual("Line 1: Object #<Object> has no method 'moveright'");
        return expect(aether.problems.errors[0].hint).toEqual("Uppercase or lowercase problem. Try `hero.moveRight()`");
      });

      it("Case thisProperties", function() {
        const history = [];
        const log = s => history.push(s);
        const attack = () => history.push('attack');
        const selfValue = {say: log, attack};
        const code = `\
b = Buildables\
`;
        const problemContext = {thisProperties: [ 'buildables' ]};
        const aether = new Aether({language: "python", problemContext});
        aether.transpile(code);
        const method = aether.createMethod(selfValue);
        aether.run(method);
        expect(aether.problems.errors.length).toEqual(1);
        expect(aether.problems.errors[0].message).toEqual("Line 1: ReferenceError: Buildables is not defined");
        return expect(aether.problems.errors[0].hint).toEqual("Try `hero.buildables`");
      });

      it("Score this value", function() {
        const history = [];
        const log = s => history.push(s);
        const attack = () => history.push('attack');
        const selfValue = {say: log, attack};
        const code = `\
elf.moveDown()\
`;
        const problemContext = {thisMethods: [ 'moveDown' ]};
        const aether = new Aether({language: "python", problemContext});
        aether.transpile(code);
        const method = aether.createMethod(selfValue);
        aether.run(method);
        expect(aether.problems.errors.length).toEqual(1);
        expect(aether.problems.errors[0].message).toEqual("Line 1: ReferenceError: elf is not defined");
        return expect(aether.problems.errors[0].hint).toEqual("Try `self`");
      });

      it("Score stringReferences", function() {
        const history = [];
        const log = s => history.push(s);
        const attack = () => history.push('attack');
        const selfValue = {say: log, attack};
        const code = `\
self.attack(brOk)\
`;
        const problemContext = {stringReferences: ['Bob', 'Brak', 'Zort']};
        const aether = new Aether({language: "python", problemContext});
        aether.transpile(code);
        const method = aether.createMethod(selfValue);
        aether.run(method);
        expect(aether.problems.errors.length).toEqual(1);
        expect(aether.problems.errors[0].message).toEqual("Line 1: ReferenceError: brOk is not defined");
        return expect(aether.problems.errors[0].hint).toEqual("Missing quotes. Try `\"Brak\"`");
      });

      it("Score thisMethods", function() {
        const selfValue = {};
        const code = `\
self.moveEight()\
`;
        const problemContext = {thisMethods: ['moveUp', 'moveRight', 'moveLeft']};
        const aether = new Aether({problemContext, language: 'python'});
        aether.transpile(code);
        const method = aether.createMethod(selfValue);
        aether.run(method);
        expect(aether.problems.errors.length).toEqual(1);
        expect(aether.problems.errors[0].type).toEqual("runtime");
        expect(aether.problems.errors[0].message).toEqual("Line 1: Object #<Object> has no method 'moveEight'");
        return expect(aether.problems.errors[0].hint).toEqual("Try `hero.moveRight()`");
      });

      it("Score thisMethods #2", function() {
        const selfValue = {};
        const code = `\
movleft\
`;
        const problemContext = {thisMethods: ['moveRight', 'moveLeft', 'moveUp', 'moveDown']};
        const aether = new Aether({language: 'python', problemContext});
        aether.transpile(code);
        const method = aether.createMethod(selfValue);
        aether.run(method);
        expect(aether.problems.errors.length).toEqual(1);
        expect(aether.problems.errors[0].message).toEqual("Line 1: ReferenceError: movleft is not defined");
        return expect(aether.problems.errors[0].hint).toEqual("Try `hero.moveLeft()`");
      });

      it("Score thisMethods #3", function() {
        const selfValue = {};
        const code = `\
moveeft\
`;
        const problemContext = {thisMethods: ['moveRight', 'moveLeft', 'moveUp', 'moveDown']};
        const aether = new Aether({language: 'python', problemContext});
        aether.transpile(code);
        const method = aether.createMethod(selfValue);
        aether.run(method);
        expect(aether.problems.errors.length).toEqual(1);
        expect(aether.problems.errors[0].message).toEqual("Line 1: ReferenceError: moveeft is not defined");
        return expect(aether.problems.errors[0].hint).toEqual("Try `hero.moveLeft()`");
      });

      it("Score thisMethods #4", function() {
        const selfValue = {};
        const code = `\
selfmoveright\
`;
        const problemContext = {thisMethods: ['moveRight', 'moveLeft', 'moveUp', 'moveDown']};
        const aether = new Aether({language: 'python', problemContext});
        aether.transpile(code);
        const method = aether.createMethod(selfValue);
        aether.run(method);
        expect(aether.problems.errors.length).toEqual(1);
        expect(aether.problems.errors[0].message).toEqual("Line 1: ReferenceError: selfmoveright is not defined");
        return expect(aether.problems.errors[0].hint).toEqual("Try `hero.moveRight()`");
      });

      it("Score thisProperties", function() {
        const history = [];
        const log = s => history.push(s);
        const attack = () => history.push('attack');
        const selfValue = {say: log, attack};
        const code = `\
b = Bildaables\
`;
        const problemContext = {thisProperties: [ 'buildables' ]};
        const aether = new Aether({language: "python", problemContext});
        aether.transpile(code);
        const method = aether.createMethod(selfValue);
        aether.run(method);
        expect(aether.problems.errors.length).toEqual(1);
        expect(aether.problems.errors[0].message).toEqual("Line 1: ReferenceError: Bildaables is not defined");
        return expect(aether.problems.errors[0].hint).toEqual("Try `hero.buildables`");
      });

      it("Exact commonThisMethods", function() {
        const selfValue = {};
        const code = `\
attack()\
`;
        const problemContext = {thisMethods: [], commonThisMethods: ['attack']};
        const aether = new Aether({problemContext, language: 'python'});
        aether.transpile(code);
        const method = aether.createMethod(selfValue);
        aether.run(method);
        expect(aether.problems.errors.length).toEqual(1);
        expect(aether.problems.errors[0].type).toEqual('runtime');
        expect(aether.problems.errors[0].message).toEqual("Line 1: ReferenceError: attack is not defined");
        return expect(aether.problems.errors[0].hint).toEqual("You do not have an item equipped with the attack skill.");
      });

      it("Case commonThisMethods", function() {
        const selfValue = {};
        const code = `\
ATTACK()\
`;
        const problemContext = {thisMethods: [], commonThisMethods: ['attack']};
        const aether = new Aether({problemContext, language: 'python'});
        aether.transpile(code);
        const method = aether.createMethod(selfValue);
        aether.run(method);
        expect(aether.problems.errors.length).toEqual(1);
        expect(aether.problems.errors[0].type).toEqual('runtime');
        expect(aether.problems.errors[0].message).toEqual("Line 1: ReferenceError: ATTACK is not defined");
        return expect(aether.problems.errors[0].hint).toEqual("Did you mean attack? You do not have an item equipped with that skill.");
      });

      it("Score commonThisMethods", function() {
        const selfValue = {};
        const code = `\
atac()\
`;
        const problemContext = {thisMethods: [], commonThisMethods: ['attack']};
        const aether = new Aether({problemContext, language: 'python'});
        aether.transpile(code);
        const method = aether.createMethod(selfValue);
        aether.run(method);
        expect(aether.problems.errors.length).toEqual(1);
        expect(aether.problems.errors[0].type).toEqual('runtime');
        expect(aether.problems.errors[0].message).toEqual("Line 1: ReferenceError: atac is not defined");
        return expect(aether.problems.errors[0].hint).toEqual("Did you mean attack? You do not have an item equipped with that skill.");
      });

      return it('enemy-ish variable is not defined', function() {
        const dude = { attack() {} };
        const code = 'self.attack(enemy3)';
        const problemContext = { thisMethods: ['findNearestEnemy'] };
        let aether = new Aether({ language: 'python', problemContext });
        aether.transpile(code);
        aether.run(aether.createFunction().bind(dude));
        expect(aether.problems.errors[0].hint).toBe("There is no `enemy3`. Use `enemy3 = hero.findNearestEnemy()` first.");

        aether = new Aether({ language: 'javascript', problemContext });
        aether.transpile(code);
        aether.run(aether.createFunction().bind(dude));
        return expect(aether.problems.errors[0].hint).toBe("There is no `enemy3`. Use `var enemy3 = hero.findNearestEnemy()` first.");
      });
    });


    describe("Missing property", () => it("self.self.moveUp()", function() {
      const selfValue = {};
      const code = `\
self.self.moveUp()\
`;
      const problemContext = {thisMethods: ['moveUp'], commonThisMethods: ['attack']};
      const aether = new Aether({problemContext, language: 'python'});
      aether.transpile(code);
      const method = aether.createMethod(selfValue);
      aether.run(method);
      expect(aether.problems.errors.length).toEqual(1);
      expect(aether.problems.errors[0].type).toEqual('runtime');
      expect(aether.problems.errors[0].message).toEqual("Line 1: Cannot call method 'moveUp' of undefined");
      return expect(aether.problems.errors[0].hint).toEqual("Try `self.moveUp()`");
    }));

    return describe("transforms.makeCheckIncompleteMembers", () => it("Incomplete 'this' and available method", function() {
      const selfValue = {};
      const code = `\
this.moveUp\
`;
      const problemContext = {thisMethods: ['moveUp']};
      const aether = new Aether({problemContext});
      aether.transpile(code);
      const method = aether.createMethod(selfValue);
      aether.run(method);
      expect(aether.problems.errors.length).toEqual(1);
      expect(aether.problems.errors[0].message).toEqual("this.moveUp has no effect. It needs parentheses: this.moveUp()");
      return expect(aether.problems.errors[0].hint).toEqual("");
    }));
  });
});
