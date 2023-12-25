/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const Aether = require('../aether');
const lodash = require('lodash');


describe("JavaScript Test Suite", function() {


  xit("Lowdash", function() {
    const aether = new Aether({language: "javascript", yieldConditionally: true, simpleLoops: true});
    ({save(x) { return this.result = x; }});
    const result = null;
    const dude =
      {lodash};

    const code = `\
var fn = function(x) { var w = x*x; return w; };
return this.result = this.lodash.map([1,2,3,4], fn)\
`;
    aether.transpile(code);
    const f = aether.createFunction();
    const gen = f.apply(dude);
    expect(gen.next().done).toEqual(true);
    return expect(dude.result).toEqual([1,4,9,16]);
});

  xdescribe("Errors", function() {
    const aether = new Aether({language: "javascript"});

    it("Transpile error, missing )", function() {
      const code = `\
function fn() {
  return 45;
}
var x = = fn();\
`;
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(2);
      expect(/Expected an identifier and instead/.test(aether.problems.errors[0].message)).toBe(true);
      //expect(aether.problems.errors[0].range).toEqual([ { ofs : 31, row : 3, col : 0 }, { ofs : 46, row : 3, col : 15 } ])
      return expect(/Line 4: Unexpected token =/.test(aether.problems.errors[1].message)).toBe(true);
    });
      //expect(aether.problems.errors[1].range).toEqual([ { ofs : 39, row : 3, col : 8 }, { ofs : 40, row : 3, col : 9 } ])

    xit("Missing this: x() row 0", function() {
      const code = "x();";
      expect(aether.problems.errors.length).toEqual(1);
      expect(aether.problems.errors[0].message).toEqual("Missing `this` keyword; should be `this.x`.");
      return expect(aether.problems.errors[0].range).toEqual([ { ofs: 0, row: 0, col: 0 }, { ofs: 3, row: 0, col: 3 } ]);
    });

    xit("Missing this: x() row 1", function() {
      const code = `\
var y = 5;
x();\
`;
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(1);
      expect(aether.problems.errors[0].message).toEqual("Missing `this` keyword; should be `this.x`.");
      return expect(aether.problems.errors[0].range).toEqual([ { ofs: 11, row: 1, col: 0 }, { ofs: 14, row: 1, col: 3 } ]);
    });

    xit("Missing this: x() row 3", function() {
      const code = `\
var y = 5;
var s = 'some other stuff';
if (y === 5)
  x();\
`;
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(1);
      expect(aether.problems.errors[0].message).toEqual("Missing `this` keyword; should be `this.x`.");
      return expect(aether.problems.errors[0].range).toEqual([ { ofs: 54, row: 3, col: 2 }, { ofs: 57, row: 3, col: 5 } ]);
    });

    xit("No effect: this.getItems missing parentheses", function() {
      const code = `\
this.getItems\
`;
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(1);
      expect(aether.problems.errors[0].message).toEqual('this.getItems has no effect.');
      expect(aether.problems.errors[0].hint).toEqual('Is it a method? Those need parentheses: this.getItems()');
      return expect(aether.problems.errors[0].range).toEqual([ { ofs : 0, row : 0, col : 0 }, { ofs : 13, row : 0, col : 13 } ]);
    });

    xit("this.getItems missing parentheses row 1", function() {
      const code = `\
var x = 5;
this.getItems\
`;
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(1);
      expect(aether.problems.errors[0].message).toEqual('this.getItems has no effect.');
      expect(aether.problems.errors[0].hint).toEqual('Is it a method? Those need parentheses: this.getItems()');
      return expect(aether.problems.errors[0].range).toEqual([ { ofs : 11, row : 1, col : 0 }, { ofs : 24, row : 1, col : 13 } ]);
    });

    it("Incomplete string", function() {
      const code = `\
var s = 'hi
return s;\
`;
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(2);
      return expect(aether.problems.errors[0].message).toEqual("Line 1: Unclosed string.");
    });
      // https://github.com/codecombat/aether/issues/113
      // expect(aether.problems.errors[0].range).toEqual([ { ofs : 8, row : 0, col : 8 }, { ofs : 11, row : 0, col : 11 } ])

    return it("Runtime ReferenceError", function() {
      const code = `\
var x = 5;
var y = x + z;\
`;
      aether.transpile(code);
      aether.run();
      console.log(aether.esperEngine.options);
      console.log(aether.problems.errors);
      expect(aether.problems.errors.length).toEqual(1);
      expect(aether.problems.errors[0].message).toEqual("Line 2: ReferenceError: z is not defined");
      return expect(aether.problems.errors[0].range).toEqual([ { ofs : 23, row : 1, col : 12 }, { ofs : 24, row : 1, col : 13 } ]);
    });
  });

  describe("Warning", function() {
    const aether = new Aether({language: "javascript"});

    it('siforce semicolon usemple', function() {
      const code = `\
this.say("a")
this.say("b")\
`;
      aether.transpile(code);
      return expect(aether.problems.warnings.length).toEqual(2);
    });

    return it("if (x == 5);", function() {
      const code = `\
var x = 5;
if (x == 6) foo();
if (x == 5);
  x++;\
`;
      aether.transpile(code);
      expect(aether.problems.warnings.length).toEqual(1);
      expect(aether.problems.warnings[0].message).toEqual("Don't put a ';' after an if statement.");
      return expect(aether.problems.warnings[0].range).toEqual([ { ofs : 41, row : 2, col : 11 }, { ofs : 42, row : 2, col : 12 } ]);
    });
  });

  xdescribe("Traceur compilation with ES6", function() {
    let aether = new Aether({languageVersion: "ES6"});
    it("should compile generator functions", function() {
      const code = `\
var x = 3;
function* gen(z) {
  yield z;
  yield z + x;
  yield z * x;
}\
`;
      const compiled = aether.traceurify(code);
      eval(compiled);
      const hoboz = gen(5);
      expect(hoboz.next().value).toEqual(5);
      expect(hoboz.next().value).toEqual(8);
      expect(hoboz.next().value).toEqual(15);
      return expect(hoboz.next().done).toEqual(true);
    });

    return it("should compile default parameters", function() {
      aether = new Aether({languageVersion: "ES6"});
      const code = `\
function hobaby(name, codes = 'JavaScript', livesIn = 'USA') {
  return 'name: ' + name + ', codes: ' + codes + ', livesIn: ' + livesIn;
};\
`;
      const compiled = aether.traceurify(code);
      eval(compiled);
      return expect(hobaby("A yeti!")).toEqual('name: A yeti!, codes: JavaScript, livesIn: USA');
    });
  });

  xdescribe("Conditional yielding", function() {
    const aether = new Aether({yieldConditionally: true, functionName: 'foo'});
    return it("should yield when necessary", function() {
      const dude = {
        charge() { return "attack!"; },
        hesitate() { return aether._shouldYield = true; }
      };
      const code = `\
this.charge();
this.hesitate();
this.hesitate();
return this.charge();\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(false);
      return expect(gen.next().done).toEqual(true);
    });
  });

  xdescribe("Automatic yielding", function() {
    const aether = new Aether({yieldAutomatically: true, functionName: 'foo'});
    it("should yield a lot", function() {
      let i;
      const dude =
        {charge() { return "attack!"; }};
      const code = `\
this.charge();
var x = 3;
x += 5 * 8;
return this.charge();\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);
      // At least four times
      for (i = 0; i < 4; i++) {
        expect(gen.next().done).toEqual(false);
      }
      // Should stop eventually
      while (i < 100) {
        if (gen.next().done) { break; } else { ++i; }
      }
      return expect(i < 100).toBe(true);
    });

    return it("with user method", function() {
      let i;
      const dude =
        {charge() { return "attack!"; }};
      const code = `\
function f(self) {
  self.charge();
}
f(this);
var x = 3;
x += 5 * 8;
return this.charge();\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);
      // At least four times
      for (i = 0; i < 4; i++) {
        expect(gen.next().done).toEqual(false);
      }
      // Should stop eventually
      while (i < 100) {
        if (gen.next().done) { break; } else { ++i; }
      }
      return expect(i < 100).toBe(true);
    });
  });

  xdescribe("No yielding", function() {
    const aether = new Aether;
    return it("should not yield", function() {
      const dude = {
        charge() { return "attack!"; },
        hesitate() { return aether._shouldYield = true; }
      };
      const code = `\
this.charge();
this.hesitate();
this.hesitate();
return this.charge();\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const ret = f.apply(dude);
      return expect(ret).toEqual("attack!");
    });
  });

  describe("Yielding within a while-loop", function() {
    let aether = new Aether({yieldConditionally: true});
    it("should handle breaking out of a while loop with yields inside", function() {
      const dude = {
        slay() { return this.enemy = "slain!"; },
        hesitate() { return aether._shouldYield = true; }
      };
      const code = `\
while(true) {
  this.hesitate();
  this.hesitate();
  this.slay();
  if(this.enemy === 'slain!')
     break;
}\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(false);
      return expect(gen.next().done).toEqual(true);
    });

    aether = new Aether({yieldConditionally: true});
    return it("should handle breaking and continuing in a while loop with yields inside", function() {
      const dude = {
        slay() { return this.enemy = "slain!"; },
        hesitate() { return aether._shouldYield = true; }
      };
      const code = `\
var i = 0;
while (true) {
    if (i < 3) {
        this.slay()
        this.hesitate();
        i++;
        continue;
    } else
        return null;
    break;
}\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(false);
      return expect(gen.next().done).toEqual(true);
    });
  });

  xdescribe("User method conditional yielding", function() {
    const aether = new Aether({yieldConditionally: true});
    it("Simple fn decl", function() {
      const dude = {
        slay() { return this.enemy = "slain!"; },
        hesitate() { return aether._shouldYield = true; }
      };
      const code = `\
function f(self) {
  self.hesitate();
  self.hesitate();
  self.slay();
}
f(this);\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(true);
      return expect(dude.enemy).toEqual("slain!");
    });

    it("Fn decl after call", function() {
      const dude = {
        slay() { return this.enemy = "slain!"; },
        hesitate() { return aether._shouldYield = true; }
      };
      const code = `\
f(this);
function f(self) {
  self.hesitate();
  self.hesitate();
  self.slay();
}\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(true);
      return expect(dude.enemy).toEqual("slain!");
    });

    it("Simple fn expr", function() {
      const dude = {
        slay() { return this.enemy = "slain!"; },
        hesitate() { return aether._shouldYield = true; }
      };
      const code = `\
this.f = function() {
  this.hesitate();
  this.hesitate();
  this.hesitate();
};
this.f();
this.slay();\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(true);
      return expect(dude.enemy).toEqual("slain!");
    });

    it("Named fn expr", function() {
      const dude = {
        slay() { return this.enemy = "slain!"; },
        hesitate() { return aether._shouldYield = true; }
      };
      const code = `\
this.f = function named() {
  this.hesitate();
  this.hesitate();
  this.hesitate();
};
this.f();
this.slay();\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(true);
      return expect(dude.enemy).toEqual("slain!");
    });

    it("IIFE", function() {
      const dude = {
        slay() { return this.enemy = "slain!"; },
        hesitate() { return aether._shouldYield = true; }
      };
      const code = `\
(function (self) {
  for (var i = 0, max = 3; i < max; ++i) {
    self.hesitate();
  }
})(this);
this.slay();\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(true);
      return expect(dude.enemy).toEqual("slain!");
    });

    it("IIFE with .call()", function() {
      const dude = {
        slay() { return this.enemy = "slain!"; },
        hesitate() { return aether._shouldYield = true; }
      };
      const code = `\
(function () {
  for (var i = 0, max = 3; i < max; ++i) {
    this.hesitate();
  }
}).call(this);
this.slay();\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(true);
      return expect(dude.enemy).toEqual("slain!");
    });

    it("IIFE without generatorify", function() {
      const dude = {
        slay() { return this.enemy = "slain!"; },
        hesitate() { return aether._shouldYield = true; }
      };
      const code = `\
(function (self) {
  self.slay();
})(this);\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);
      expect(gen.next().done).toEqual(true);
      return expect(dude.enemy).toEqual("slain!");
    });

    it("Nested methods one generatorify", function() {
      const dude = {
        slay() { return this.enemy = "slain!"; },
        hesitate() { return aether._shouldYield = true; }
      };
      const code = `\
(function (self) {
  function f(self) {
    self.hesitate();
  }
  f(self);
  self.slay();
})(this);\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(true);
      return expect(dude.enemy).toEqual("slain!");
    });

    it("Nested methods many generatorify", function() {
      const dude = {
        slay() { return this.enemy = "slain!"; },
        hesitate() { return aether._shouldYield = true; }
      };
      const code = `\
(function (self) {
  function f(self) {
    self.hesitate();
    var f2 = function(self, n) {
      for (var i = 0; i < n; i++) {
        self.hesitate();
      }
    }
    f2(self, 2);
    self.hesitate();
  }
  f(self);
  self.hesitate();
  self.slay();
})(this);\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(true);
      return expect(dude.enemy).toEqual("slain!");
    });

    it("Call user fn decl from another user method", function() {
      const dude = {
        slay() { return this.enemy = "slain!"; },
        hesitate() { return aether._shouldYield = true; }
      };
      const code = `\
 function f(self) {
    self.hesitate();
    b(self);
    (function () {
        self.hesitate();
    })();
}
function b(self) {
    self.hesitate();
}
f(this);
this.slay();\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(true);
      return expect(dude.enemy).toEqual("slain!");
    });

    it("Call user fn expr from another user method", function() {
      const dude = {
        slay() { return this.enemy = "slain!"; },
        hesitate() { return aether._shouldYield = true; }
      };
      const code = `\
this.b = function () {
    this.hesitate();
};
 function f(self) {
    var x = self;
    x.b();
}
var y = this;
f(y);
this.slay();\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(true);
      return expect(dude.enemy).toEqual("slain!");
    });

    it("Complex objects", function() {
      const dude = {
        slay() { return this.enemy = "slain!"; },
        hesitate() { return aether._shouldYield = true; }
      };
      const code = `\
var o1 = {};
o1.m = function(self) {
  self.hesitate();
};
o1.o2 = {};
o1.o2.m = function(self) {
  self.hesitate();
};
o1.m(this);
o1.o2.m(this);
this.slay();\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(true);
      return expect(dude.enemy).toEqual("slain!");
    });

    it("Functions as parameters", function() {
      const dude = {
        slay() { return this.enemy = "slain!"; },
        hesitate() { return aether._shouldYield = true; }
      };
      const code = `\
function f(m, self) {
    m(self);
}
function b(self) {
  self.hesitate();
}
f(b, this);
this.slay();\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(true);
      return expect(dude.enemy).toEqual("slain!");
    });

    it("Nested clauses", function() {
      const dude = {
        slay() { return this.enemy = "slain!"; },
        hesitate() { return aether._shouldYield = true; }
      };
      const code = `\
this.b = function (self) {
    self.hesitate();
}
function f(self) {
  self.hesitate();
  self.b(self);
}
if (true) {
  f(this);
}
for (var i = 0; i < 2; i++) {
  if (i === 1) {
    f(this);
  }
}
var inc = 0;
while (inc < 2) {
  f(this);
  inc += 1;
}
this.slay();\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(true);
      return expect(dude.enemy).toEqual("slain!");
    });

    it("Recursive user function", function() {
      const dude = {
        slay() { return this.enemy = "slain!"; },
        hesitate() { return aether._shouldYield = true; }
      };
      const code = `\
function f(self, n) {
  self.hesitate();
  if (n > 0) {
    f(self, n - 1);
  }
}
f(this, 2);
this.slay();\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(true);
      return expect(dude.enemy).toEqual("slain!");
    });

    // TODO: Method reassignment not supported yet
    //it "Reassigning methods", ->
    //  dude =
    //    slay: -> @enemy = "slain!"
    //    hesitate: -> aether._shouldYield = true
    //  code = """
    //    function f(self) {
    //      self.hesitate();
    //    }
    //    var b = f;
    //    b(this);
    //    this.slay();
    //  """
    //  aether.transpile code
    //  f = aether.createFunction()
    //  gen = f.apply dude
    //  expect(gen.next().done).toEqual false
    //  expect(gen.next().done).toEqual true
    //  expect(dude.enemy).toEqual "slain!"

    // TODO: Calling inner function returned from another function is not supported yet
    //it "Return user function", ->
    //  dude =
    //    slay: -> @enemy = "slain!"
    //    hesitate: -> aether._shouldYield = true
    //  code = """
    //    function f(self) {
    //      self.hesitate();
    //    }
    //    function b() {
    //      return f;
    //    }
    //    var m = b();
    //    m(this);
    //    this.slay();
    //  """
    //  aether.transpile code
    //  f = aether.createFunction()
    //  gen = f.apply dude
    //  expect(gen.next().done).toEqual false
    //  expect(gen.next().done).toEqual true
    //  expect(dude.enemy).toEqual "slain!"

    it("Resolve user method call on function parameter", function() {
      const dude = {
        slay() { return this.enemy = "slain!"; },
        hesitate() { return aether._shouldYield = true; }
      };
      const code = `\
this.chooseTarget = function(friend) {
    friend.slay();
};
this.commandFriend = function() {
    this.chooseTarget(this);
};
this.commandFriend();\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);
      expect(gen.next().done).toEqual(true);
      return expect(dude.enemy).toEqual("slain!");
    });

    it("Resolve multiple user method calls on function parameter", function() {
      const dude = {
        slay() { return this.enemy = "slain!"; },
        hesitate() { return aether._shouldYield = true; }
      };
      const code = `\
function fn1(arg1) {
    arg1.hesitate();
}
function fn2(arg2) {
    arg2.slay();
}
fn1(this);
fn2(this);\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(true);
      return expect(dude.enemy).toEqual("slain!");
    });

    return it("Resolve user defined function that has no call to it", function() {
      const dude = {
        slay() { return this.enemy = "slain!"; },
        hesitate() { return aether._shouldYield = true; }
      };
      const code = `\
this.getPriorityTarget = function(who) {
    who.getNearest();
};
this.commandSoldier = function(soldier) {
    this.getPriorityTarget(soldier);
};
// First two user functions should not break user function lookup required for doStuff to yield properly
this.doStuff = function() {
  this.hesitate();
}
this.doStuff();
this.slay();\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(true);
      return expect(dude.enemy).toEqual("slain!");
    });
  });

  describe("Simple loop", function() {
    it("loop{", function() {
      const code = `\
var total = 0
while (true) {
  total += 1
  break;
}
return total\
`;
      const aether = new Aether({language: "javascript", simpleLoops: true});
      aether.transpile(code);
      return expect(aether.run()).toEqual(1);
    });

    it("loop {}", function() {
      const code = `\
var total = 0
while (true) { total += 1; if (total >= 12) {break;}}
return total\
`;
      const aether = new Aether({language: "javascript", simpleLoops: true});
      aether.transpile(code);
      return expect(aether.run()).toEqual(12);
    });

    it("Conditional yielding", function() {
      const aether = new Aether({yieldConditionally: true, simpleLoops: true});
      const dude = {
        killCount: 0,
        slay() {
          this.killCount += 1;
          return aether._shouldYield = true;
        },
        getKillCount() { return this.killCount; }
      };
      const code = `\
while (true) {
  this.slay();
  break;
}
while (true) {
  this.slay();
  if (this.getKillCount() >= 5) {
    break;
  }
}
while (true) {
  this.slay();
  break;
}\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);
      for (let i = 1; i <= 6; i++) {
        expect(gen.next().done).toEqual(false);
        expect(dude.killCount).toEqual(i);
      }
      expect(gen.next().done).toEqual(true);
      return expect(dude.killCount).toEqual(6);
    });

    it("Conditional yielding infinite loop", function() {
      const aether = new Aether({yieldConditionally: true, simpleLoops: true});
      const code = `\
var x = 0;
while (true) {
  x++;
}\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f();
      return __range__(0, 100, true).map((i) =>
        expect(gen.next().done).toEqual(false));
    });

    it("Conditional yielding empty loop", function() {
      const aether = new Aether({yieldConditionally: true, simpleLoops: true});
      const dude = {
        killCount: 0,
        slay() {
          this.killCount += 1;
          return aether._shouldYield = true;
        },
        getKillCount() { return this.killCount; }
      };
      const code = `\
var x = 0;
while (true) {
  x++;
  if (x >= 3) break;
}\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(false);
      return expect(gen.next().done).toEqual(true);
    });

    it("Conditional yielding mixed loops", function() {
      let i;
      const aether = new Aether({yieldConditionally: true, simpleLoops: true});
      const dude = {
        killCount: 0,
        slay() {
          this.killCount += 1;
          return aether._shouldYield = true;
        },
        getKillCount() { return this.killCount; }
      };
      const code = `\
while (true) {
  this.slay();
  if (this.getKillCount() >= 5) {
    break;
  }
}
function f() {
  var x = 0;
  while (true) {
    x++;
    if (x > 10) break;
  }
  while (true) {
    this.slay();
    if (this.getKillCount() >= 15) {
      break;
    }
  }
}
f.call(this);
while (true) {
  this.slay();
  break;
}\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);
      for (i = 1; i <= 5; i++) {
        expect(gen.next().done).toEqual(false);
        expect(dude.killCount).toEqual(i);
      }
      for (i = 1; i <= 10; i++) {
        expect(gen.next().done).toEqual(false);
        expect(dude.killCount).toEqual(5);
      }
      for (i = 6; i <= 15; i++) {
        expect(gen.next().done).toEqual(false);
        expect(dude.killCount).toEqual(i);
      }
      expect(gen.next().done).toEqual(false);
      expect(dude.killCount).toEqual(16);
      expect(gen.next().done).toEqual(true);
      return expect(dude.killCount).toEqual(16);
    });

    it("Conditional yielding nested loops", function() {
      let i, j;
      const aether = new Aether({yieldConditionally: true, simpleLoops: true});
      const dude = {
        killCount: 0,
        slay() {
          this.killCount += 1;
          return aether._shouldYield = true;
        },
        getKillCount() { return this.killCount; }
      };
      const code = `\
function f() {
  // outer auto yield, inner yield
  var x = 0;
  while (true) {
    var y = 0;
    while (true) {
      this.slay();
      y++;
      if (y >= 2) break;
    }
    x++;
    if (x >= 3) break;
  }
}
f.call(this);

// outer yield, inner auto yield
var x = 0;
while (true) {
  this.slay();
  var y = 0;
  while (true) {
    y++;
    if (y >= 4) break;
  }
  x++;
  if (x >= 5) break;
}

// outer and inner auto yield
x = 0;
while (true) {
  y = 0;
  while (true) {
    y++;
    if (y >= 6) break;
  }
  x++;
  if (x >= 7) break;
}

// outer and inner yields
x = 0;
while (true) {
  this.slay();
  y = 0;
  while (true) {
    this.slay();
    y++;
    if (y >= 9) break;
  }
  x++;
  if (x >= 8) break;
}\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);

      // NOTE: keep in mind no-yield loops break before invisible automatic yield

      // outer auto yield, inner yield
      for (i = 1; i <= 3; i++) {
        for (j = 1; j <= 2; j++) {
          expect(gen.next().done).toEqual(false);
          expect(dude.killCount).toEqual(((i - 1) * 2) + j);
        }
        if (i < 3) { expect(gen.next().done).toEqual(false); }
      }
      expect(dude.killCount).toEqual(6);

      // outer yield, inner auto yield
      let killOffset = dude.killCount;
      for (i = 1; i <= 5; i++) {
        for (j = 1; j <= 3; j++) {
          expect(gen.next().done).toEqual(false);
        }
        expect(gen.next().done).toEqual(false);
        expect(dude.killCount).toEqual(i + killOffset);
      }
      expect(dude.killCount).toEqual(6 + 5);

      // outer and inner auto yield
      killOffset = dude.killCount;
      for (i = 1; i <= 7; i++) {
        for (j = 1; j <= 5; j++) {
          expect(gen.next().done).toEqual(false);
          expect(dude.killCount).toEqual(killOffset);
        }
        if (i < 7) { expect(gen.next().done).toEqual(false); }
      }
      expect(dude.killCount).toEqual(6 + 5 + 0);

      // outer and inner yields
      killOffset = dude.killCount;
      for (i = 1; i <= 8; i++) {
        expect(gen.next().done).toEqual(false);
        for (j = 1; j <= 9; j++) {
          expect(gen.next().done).toEqual(false);
          expect(dude.killCount).toEqual(((i - 1) * 9) + i + j + killOffset);
        }
      }
      expect(dude.killCount).toEqual(6 + 5 + 0 + 80);

      expect(gen.next().done).toEqual(true);
      return expect(dude.killCount).toEqual(91);
    });

    return it("Automatic yielding", function() {
      const aether = new Aether({yieldAutomatically: true, simpleLoops: true});
      const dude = {
        killCount: 0,
        slay() { return this.killCount += 1; },
        getKillCount() { return this.killCount; }
      };
      const code = `\
while (true) {
  this.slay();
  break;
}
while (true) {
  this.slay();
  if (this.getKillCount() >= 5) {
    break;
  }
}
while (true) {
  this.slay();
  break;
}
\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);
      while (true) {
        if (gen.next().done) { break; }
      }
      return expect(dude.killCount).toEqual(6);
    });
  });

  return describe("whileTrueAutoYield", function() {
    it("while (true) {}", function() {
      const code = `\
var total = 0
while (true) { total += 1; if (total >= 12) {break;}}
return total\
`;
      const aether = new Aether({language: "javascript", whileTrueAutoYield: true});
      aether.transpile(code);
      return expect(aether.run()).toEqual(12);
    });

    it("Conditional yielding", function() {
      const aether = new Aether({yieldConditionally: true, whileTrueAutoYield: true});
      const dude = {
        killCount: 0,
        slay() {
          this.killCount += 1;
          return aether._shouldYield = true;
        },
        getKillCount() { return this.killCount; }
      };
      const code = `\
while (1 === 1) {
  this.slay();
  break;
}
while (true) {
  this.slay();
  if (this.getKillCount() >= 5) {
    break;
  }
}
while (3 === 3) {
  this.slay();
  break;
}\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);
      for (let i = 1; i <= 6; i++) {
        expect(gen.next().done).toEqual(false);
        expect(dude.killCount).toEqual(i);
      }
      expect(gen.next().done).toEqual(true);
      return expect(dude.killCount).toEqual(6);
    });

    it("Conditional yielding infinite loop", function() {
      const aether = new Aether({yieldConditionally: true, whileTrueAutoYield: true});
      const code = `\
var x = 0;
while (true) {
  x++;
}\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f();
      return __range__(0, 100, true).map((i) =>
        expect(gen.next().done).toEqual(false));
    });

    it("Conditional yielding empty loop", function() {
      const aether = new Aether({yieldConditionally: true, whileTrueAutoYield: true});
      const dude = {
        killCount: 0,
        slay() {
          this.killCount += 1;
          return aether._shouldYield = true;
        },
        getKillCount() { return this.killCount; }
      };
      const code = `\
var x = 0;
while (true) {
  x++;
  if (x >= 3) break;
}\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(false);
      return expect(gen.next().done).toEqual(true);
    });

    xit("Conditional yielding mixed loops", function() {
      let i;
      const aether = new Aether({yieldConditionally: true, whileTrueAutoYield: true});
      const dude = {
        killCount: 0,
        slay() {
          this.killCount += 1;
          return aether._shouldYield = true;
        },
        getKillCount() { return this.killCount; }
      };
      const code = `\
while (true) {
  this.slay();
  if (this.getKillCount() >= 5) {
    break;
  }
}
function f() {
  var x = 0;
  while (true) {
    x++;
    if (x > 10) break;
  }
  while (true) {
    this.slay();
    if (this.getKillCount() >= 15) {
      break;
    }
  }
}
f.call(this);
while (4 === 4) {
  this.slay();
  break;
}\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);
      for (i = 1; i <= 5; i++) {
        expect(gen.next().done).toEqual(false);
        expect(dude.killCount).toEqual(i);
      }
      for (i = 1; i <= 10; i++) {
        expect(gen.next().done).toEqual(false);
        expect(dude.killCount).toEqual(5);
      }
      for (i = 6; i <= 15; i++) {
        expect(gen.next().done).toEqual(false);
        expect(dude.killCount).toEqual(i);
      }
      expect(gen.next().done).toEqual(false);
      expect(dude.killCount).toEqual(16);
      expect(gen.next().done).toEqual(true);
      return expect(dude.killCount).toEqual(16);
    });

    it("Conditional yielding nested loops", function() {
      let i, j;
      const aether = new Aether({yieldConditionally: true, whileTrueAutoYield: true});
      const dude = {
        killCount: 0,
        slay() {
          this.killCount += 1;
          return aether._shouldYield = true;
        },
        getKillCount() { return this.killCount; }
      };
      const code = `\
function f() {
  // outer auto yield, inner yield
  var x = 0;
  while (true) {
    var y = 0;
    while (true) {
      this.slay();
      y++;
      if (y >= 2) break;
    }
    x++;
    if (x >= 3) break;
  }
}
f.call(this);

// outer yield, inner auto yield
var x = 0;
while (true) {
  this.slay();
  var y = 0;
  while (true) {
    y++;
    if (y >= 4) break;
  }
  x++;
  if (x >= 5) break;
}

// outer and inner auto yield
x = 0;
while (true) {
  y = 0;
  while (true) {
    y++;
    if (y >= 6) break;
  }
  x++;
  if (x >= 7) break;
}

// outer and inner yields
x = 0;
while (true) {
  this.slay();
  y = 0;
  while (true) {
    this.slay();
    y++;
    if (y >= 9) break;
  }
  x++;
  if (x >= 8) break;
}\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);

      // NOTE: keep in mind no-yield loops break before invisible automatic yield

      // outer auto yield, inner yield
      for (i = 1; i <= 3; i++) {
        for (j = 1; j <= 2; j++) {
          expect(gen.next().done).toEqual(false);
          expect(dude.killCount).toEqual(((i - 1) * 2) + j);
        }
        if (i < 3) { expect(gen.next().done).toEqual(false); }
      }
      expect(dude.killCount).toEqual(6);

      // outer yield, inner auto yield
      let killOffset = dude.killCount;
      for (i = 1; i <= 5; i++) {
        for (j = 1; j <= 3; j++) {
          expect(gen.next().done).toEqual(false);
        }
        expect(gen.next().done).toEqual(false);
        expect(dude.killCount).toEqual(i + killOffset);
      }
      expect(dude.killCount).toEqual(6 + 5);

      // outer and inner auto yield
      killOffset = dude.killCount;
      for (i = 1; i <= 7; i++) {
        for (j = 1; j <= 5; j++) {
          expect(gen.next().done).toEqual(false);
          expect(dude.killCount).toEqual(killOffset);
        }
        if (i < 7) { expect(gen.next().done).toEqual(false); }
      }
      expect(dude.killCount).toEqual(6 + 5 + 0);

      // outer and inner yields
      killOffset = dude.killCount;
      for (i = 1; i <= 8; i++) {
        expect(gen.next().done).toEqual(false);
        for (j = 1; j <= 9; j++) {
          expect(gen.next().done).toEqual(false);
          expect(dude.killCount).toEqual(((i - 1) * 9) + i + j + killOffset);
        }
      }
      expect(dude.killCount).toEqual(6 + 5 + 0 + 80);

      expect(gen.next().done).toEqual(true);
      return expect(dude.killCount).toEqual(91);
    });

    return it("Automatic yielding", function() {
      const aether = new Aether({yieldAutomatically: true, whileTrueAutoYield: true});
      const dude = {
        killCount: 0,
        slay() { return this.killCount += 1; },
        getKillCount() { return this.killCount; }
      };
      const code = `\
while (1 === 1) {
  this.slay();
  break;
}
while (true) {
  this.slay();
  if (this.getKillCount() >= 5) {
    break;
  }
}
while (3 === 3) {
  this.slay();
  break;
}
\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);
      while (true) {
        if (gen.next().done) { break; }
      }
      return expect(dude.killCount).toEqual(6);
    });
  });
});




function __range__(left, right, inclusive) {
  let range = [];
  let ascending = left < right;
  let end = !inclusive ? right : ascending ? right + 1 : right - 1;
  for (let i = left; ascending ? i < end : i > end; ascending ? i++ : i--) {
    range.push(i);
  }
  return range;
}