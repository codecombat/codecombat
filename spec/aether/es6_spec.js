Aether = require '../aether'
lodash = require 'lodash'


describe "JavaScript Test Suite", ->


  xit "Lowdash", ->
    aether = new Aether language: "javascript", yieldConditionally: true, simpleLoops: true
    save: (x) -> this.result = x
    result = null
    dude =
      lodash: lodash

    code = """
      var fn = function(x) { var w = x*x; return w; };
      return this.result = this.lodash.map([1,2,3,4], fn)
    """
    aether.transpile code
    f = aether.createFunction()
    gen = f.apply dude
    expect(gen.next().done).toEqual true
    expect(dude.result).toEqual [1,4,9,16]

  xdescribe "Errors", ->
    aether = new Aether language: "javascript"

    it "Transpile error, missing )", ->
      code = """
      function fn() {
        return 45;
      }
      var x = = fn();
      """
      aether.transpile(code)
      expect(aether.problems.errors.length).toEqual(2)
      expect(/Expected an identifier and instead/.test(aether.problems.errors[0].message)).toBe(true)
      #expect(aether.problems.errors[0].range).toEqual([ { ofs : 31, row : 3, col : 0 }, { ofs : 46, row : 3, col : 15 } ])
      expect(/Line 4: Unexpected token =/.test(aether.problems.errors[1].message)).toBe(true)
      #expect(aether.problems.errors[1].range).toEqual([ { ofs : 39, row : 3, col : 8 }, { ofs : 40, row : 3, col : 9 } ])

    xit "Missing this: x() row 0", ->
      code = """x();"""
      expect(aether.problems.errors.length).toEqual(1)
      expect(aether.problems.errors[0].message).toEqual("Missing `this` keyword; should be `this.x`.")
      expect(aether.problems.errors[0].range).toEqual([ { ofs: 0, row: 0, col: 0 }, { ofs: 3, row: 0, col: 3 } ])

    xit "Missing this: x() row 1", ->
      code = """
      var y = 5;
      x();
      """
      aether.transpile(code)
      expect(aether.problems.errors.length).toEqual(1)
      expect(aether.problems.errors[0].message).toEqual("Missing `this` keyword; should be `this.x`.")
      expect(aether.problems.errors[0].range).toEqual([ { ofs: 11, row: 1, col: 0 }, { ofs: 14, row: 1, col: 3 } ])

    xit "Missing this: x() row 3", ->
      code = """
      var y = 5;
      var s = 'some other stuff';
      if (y === 5)
        x();
      """
      aether.transpile(code)
      expect(aether.problems.errors.length).toEqual(1)
      expect(aether.problems.errors[0].message).toEqual("Missing `this` keyword; should be `this.x`.")
      expect(aether.problems.errors[0].range).toEqual([ { ofs: 54, row: 3, col: 2 }, { ofs: 57, row: 3, col: 5 } ])

    xit "No effect: this.getItems missing parentheses", ->
      code = """
      this.getItems
      """
      aether.transpile code
      expect(aether.problems.errors.length).toEqual(1)
      expect(aether.problems.errors[0].message).toEqual('this.getItems has no effect.')
      expect(aether.problems.errors[0].hint).toEqual('Is it a method? Those need parentheses: this.getItems()')
      expect(aether.problems.errors[0].range).toEqual([ { ofs : 0, row : 0, col : 0 }, { ofs : 13, row : 0, col : 13 } ])

    xit "this.getItems missing parentheses row 1", ->
      code = """
      var x = 5;
      this.getItems
      """
      aether.transpile code
      expect(aether.problems.errors.length).toEqual(1)
      expect(aether.problems.errors[0].message).toEqual('this.getItems has no effect.')
      expect(aether.problems.errors[0].hint).toEqual('Is it a method? Those need parentheses: this.getItems()')
      expect(aether.problems.errors[0].range).toEqual([ { ofs : 11, row : 1, col : 0 }, { ofs : 24, row : 1, col : 13 } ])

    it "Incomplete string", ->
      code = """
      var s = 'hi
      return s;
      """
      aether.transpile(code)
      expect(aether.problems.errors.length).toEqual(2)
      expect(aether.problems.errors[0].message).toEqual("Line 1: Unclosed string.")
      # https://github.com/codecombat/aether/issues/113
      # expect(aether.problems.errors[0].range).toEqual([ { ofs : 8, row : 0, col : 8 }, { ofs : 11, row : 0, col : 11 } ])

    it "Runtime ReferenceError", ->
      code = """
      var x = 5;
      var y = x + z;
      """
      aether.transpile(code)
      aether.run()
      console.log aether.esperEngine.options
      console.log(aether.problems.errors)
      expect(aether.problems.errors.length).toEqual(1)
      expect(aether.problems.errors[0].message).toEqual("Line 2: ReferenceError: z is not defined")
      expect(aether.problems.errors[0].range).toEqual([ { ofs : 23, row : 1, col : 12 }, { ofs : 24, row : 1, col : 13 } ])

  describe "Warning", ->
    aether = new Aether language: "javascript"

    it 'siforce semicolon usemple', ->
      code = """
        this.say("a")
        this.say("b")
      """
      aether.transpile(code)
      expect(aether.problems.warnings.length).toEqual(2)

    it "if (x == 5);", ->
      code = """
      var x = 5;
      if (x == 6) foo();
      if (x == 5);
        x++;
      """
      aether.transpile(code)
      expect(aether.problems.warnings.length).toEqual(1)
      expect(aether.problems.warnings[0].message).toEqual("Don't put a ';' after an if statement.")
      expect(aether.problems.warnings[0].range).toEqual([ { ofs : 41, row : 2, col : 11 }, { ofs : 42, row : 2, col : 12 } ])

  xdescribe "Traceur compilation with ES6", ->
    aether = new Aether languageVersion: "ES6"
    it "should compile generator functions", ->
      code = """
        var x = 3;
        function* gen(z) {
          yield z;
          yield z + x;
          yield z * x;
        }
      """
      compiled = aether.traceurify code
      eval(compiled)
      hoboz = gen(5)
      expect(hoboz.next().value).toEqual 5
      expect(hoboz.next().value).toEqual 8
      expect(hoboz.next().value).toEqual 15
      expect(hoboz.next().done).toEqual true

    it "should compile default parameters", ->
      aether = new Aether languageVersion: "ES6"
      code = """
      function hobaby(name, codes = 'JavaScript', livesIn = 'USA') {
        return 'name: ' + name + ', codes: ' + codes + ', livesIn: ' + livesIn;
      };
      """
      compiled = aether.traceurify code
      eval(compiled)
      expect(hobaby("A yeti!")).toEqual 'name: A yeti!, codes: JavaScript, livesIn: USA'

  xdescribe "Conditional yielding", ->
    aether = new Aether yieldConditionally: true, functionName: 'foo'
    it "should yield when necessary", ->
      dude =
        charge: -> "attack!"
        hesitate: -> aether._shouldYield = true
      code = """
        this.charge();
        this.hesitate();
        this.hesitate();
        return this.charge();
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual true

  xdescribe "Automatic yielding", ->
    aether = new Aether yieldAutomatically: true, functionName: 'foo'
    it "should yield a lot", ->
      dude =
        charge: -> "attack!"
      code = """
        this.charge();
        var x = 3;
        x += 5 * 8;
        return this.charge();
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude
      # At least four times
      for i in [0 ... 4]
        expect(gen.next().done).toEqual false
      # Should stop eventually
      while i < 100
        if gen.next().done then break else ++i
      expect(i < 100).toBe true

    it "with user method", ->
      dude =
        charge: -> "attack!"
      code = """
        function f(self) {
          self.charge();
        }
        f(this);
        var x = 3;
        x += 5 * 8;
        return this.charge();
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude
      # At least four times
      for i in [0 ... 4]
        expect(gen.next().done).toEqual false
      # Should stop eventually
      while i < 100
        if gen.next().done then break else ++i
      expect(i < 100).toBe true

  xdescribe "No yielding", ->
    aether = new Aether
    it "should not yield", ->
      dude =
        charge: -> "attack!"
        hesitate: -> aether._shouldYield = true
      code = """
        this.charge();
        this.hesitate();
        this.hesitate();
        return this.charge();
      """
      aether.transpile code
      f = aether.createFunction()
      ret = f.apply dude
      expect(ret).toEqual "attack!"

  describe "Yielding within a while-loop", ->
    aether = new Aether yieldConditionally: true
    it "should handle breaking out of a while loop with yields inside", ->
      dude =
        slay: -> @enemy = "slain!"
        hesitate: -> aether._shouldYield = true
      code = """
        while(true) {
          this.hesitate();
          this.hesitate();
          this.slay();
          if(this.enemy === 'slain!')
             break;
        }
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual true

    aether = new Aether yieldConditionally: true
    it "should handle breaking and continuing in a while loop with yields inside", ->
      dude =
        slay: -> @enemy = "slain!"
        hesitate: -> aether._shouldYield = true
      code = """
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
        }
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual true

  xdescribe "User method conditional yielding", ->
    aether = new Aether yieldConditionally: true
    it "Simple fn decl", ->
      dude =
        slay: -> @enemy = "slain!"
        hesitate: -> aether._shouldYield = true
      code = """
        function f(self) {
          self.hesitate();
          self.hesitate();
          self.slay();
        }
        f(this);
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual true
      expect(dude.enemy).toEqual "slain!"

    it "Fn decl after call", ->
      dude =
        slay: -> @enemy = "slain!"
        hesitate: -> aether._shouldYield = true
      code = """
        f(this);
        function f(self) {
          self.hesitate();
          self.hesitate();
          self.slay();
        }
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual true
      expect(dude.enemy).toEqual "slain!"

    it "Simple fn expr", ->
      dude =
        slay: -> @enemy = "slain!"
        hesitate: -> aether._shouldYield = true
      code = """
        this.f = function() {
          this.hesitate();
          this.hesitate();
          this.hesitate();
        };
        this.f();
        this.slay();
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual true
      expect(dude.enemy).toEqual "slain!"

    it "Named fn expr", ->
      dude =
        slay: -> @enemy = "slain!"
        hesitate: -> aether._shouldYield = true
      code = """
        this.f = function named() {
          this.hesitate();
          this.hesitate();
          this.hesitate();
        };
        this.f();
        this.slay();
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual true
      expect(dude.enemy).toEqual "slain!"

    it "IIFE", ->
      dude =
        slay: -> @enemy = "slain!"
        hesitate: -> aether._shouldYield = true
      code = """
        (function (self) {
          for (var i = 0, max = 3; i < max; ++i) {
            self.hesitate();
          }
        })(this);
        this.slay();
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual true
      expect(dude.enemy).toEqual "slain!"

    it "IIFE with .call()", ->
      dude =
        slay: -> @enemy = "slain!"
        hesitate: -> aether._shouldYield = true
      code = """
        (function () {
          for (var i = 0, max = 3; i < max; ++i) {
            this.hesitate();
          }
        }).call(this);
        this.slay();
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual true
      expect(dude.enemy).toEqual "slain!"

    it "IIFE without generatorify", ->
      dude =
        slay: -> @enemy = "slain!"
        hesitate: -> aether._shouldYield = true
      code = """
        (function (self) {
          self.slay();
        })(this);
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude
      expect(gen.next().done).toEqual true
      expect(dude.enemy).toEqual "slain!"

    it "Nested methods one generatorify", ->
      dude =
        slay: -> @enemy = "slain!"
        hesitate: -> aether._shouldYield = true
      code = """
        (function (self) {
          function f(self) {
            self.hesitate();
          }
          f(self);
          self.slay();
        })(this);
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual true
      expect(dude.enemy).toEqual "slain!"

    it "Nested methods many generatorify", ->
      dude =
        slay: -> @enemy = "slain!"
        hesitate: -> aether._shouldYield = true
      code = """
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
        })(this);
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual true
      expect(dude.enemy).toEqual "slain!"

    it "Call user fn decl from another user method", ->
      dude =
        slay: -> @enemy = "slain!"
        hesitate: -> aether._shouldYield = true
      code = """
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
        this.slay();
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual true
      expect(dude.enemy).toEqual "slain!"

    it "Call user fn expr from another user method", ->
      dude =
        slay: -> @enemy = "slain!"
        hesitate: -> aether._shouldYield = true
      code = """
        this.b = function () {
            this.hesitate();
        };
         function f(self) {
            var x = self;
            x.b();
        }
        var y = this;
        f(y);
        this.slay();
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual true
      expect(dude.enemy).toEqual "slain!"

    it "Complex objects", ->
      dude =
        slay: -> @enemy = "slain!"
        hesitate: -> aether._shouldYield = true
      code = """
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
        this.slay();
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual true
      expect(dude.enemy).toEqual "slain!"

    it "Functions as parameters", ->
      dude =
        slay: -> @enemy = "slain!"
        hesitate: -> aether._shouldYield = true
      code = """
        function f(m, self) {
            m(self);
        }
        function b(self) {
          self.hesitate();
        }
        f(b, this);
        this.slay();
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual true
      expect(dude.enemy).toEqual "slain!"

    it "Nested clauses", ->
      dude =
        slay: -> @enemy = "slain!"
        hesitate: -> aether._shouldYield = true
      code = """
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
        this.slay();
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual true
      expect(dude.enemy).toEqual "slain!"

    it "Recursive user function", ->
      dude =
        slay: -> @enemy = "slain!"
        hesitate: -> aether._shouldYield = true
      code = """
        function f(self, n) {
          self.hesitate();
          if (n > 0) {
            f(self, n - 1);
          }
        }
        f(this, 2);
        this.slay();
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual true
      expect(dude.enemy).toEqual "slain!"

    # TODO: Method reassignment not supported yet
    #it "Reassigning methods", ->
    #  dude =
    #    slay: -> @enemy = "slain!"
    #    hesitate: -> aether._shouldYield = true
    #  code = """
    #    function f(self) {
    #      self.hesitate();
    #    }
    #    var b = f;
    #    b(this);
    #    this.slay();
    #  """
    #  aether.transpile code
    #  f = aether.createFunction()
    #  gen = f.apply dude
    #  expect(gen.next().done).toEqual false
    #  expect(gen.next().done).toEqual true
    #  expect(dude.enemy).toEqual "slain!"

    # TODO: Calling inner function returned from another function is not supported yet
    #it "Return user function", ->
    #  dude =
    #    slay: -> @enemy = "slain!"
    #    hesitate: -> aether._shouldYield = true
    #  code = """
    #    function f(self) {
    #      self.hesitate();
    #    }
    #    function b() {
    #      return f;
    #    }
    #    var m = b();
    #    m(this);
    #    this.slay();
    #  """
    #  aether.transpile code
    #  f = aether.createFunction()
    #  gen = f.apply dude
    #  expect(gen.next().done).toEqual false
    #  expect(gen.next().done).toEqual true
    #  expect(dude.enemy).toEqual "slain!"

    it "Resolve user method call on function parameter", ->
      dude =
        slay: -> @enemy = "slain!"
        hesitate: -> aether._shouldYield = true
      code = """
        this.chooseTarget = function(friend) {
            friend.slay();
        };
        this.commandFriend = function() {
            this.chooseTarget(this);
        };
        this.commandFriend();
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude
      expect(gen.next().done).toEqual true
      expect(dude.enemy).toEqual "slain!"

    it "Resolve multiple user method calls on function parameter", ->
      dude =
        slay: -> @enemy = "slain!"
        hesitate: -> aether._shouldYield = true
      code = """
        function fn1(arg1) {
            arg1.hesitate();
        }
        function fn2(arg2) {
            arg2.slay();
        }
        fn1(this);
        fn2(this);
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual true
      expect(dude.enemy).toEqual "slain!"

    it "Resolve user defined function that has no call to it", ->
      dude =
        slay: -> @enemy = "slain!"
        hesitate: -> aether._shouldYield = true
      code = """
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
        this.slay();
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual true
      expect(dude.enemy).toEqual "slain!"

  describe "Simple loop", ->
    it "loop{", ->
      code = """
      var total = 0
      while (true) {
        total += 1
        break;
      }
      return total
      """
      aether = new Aether language: "javascript", simpleLoops: true
      aether.transpile(code)
      expect(aether.run()).toEqual(1)

    it "loop {}", ->
      code = """
      var total = 0
      while (true) { total += 1; if (total >= 12) {break;}}
      return total
      """
      aether = new Aether language: "javascript", simpleLoops: true
      aether.transpile(code)
      expect(aether.run()).toEqual(12)

    it "Conditional yielding", ->
      aether = new Aether yieldConditionally: true, simpleLoops: true
      dude =
        killCount: 0
        slay: ->
          @killCount += 1
          aether._shouldYield = true
        getKillCount: -> return @killCount
      code = """
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
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude
      for i in [1..6]
        expect(gen.next().done).toEqual false
        expect(dude.killCount).toEqual i
      expect(gen.next().done).toEqual true
      expect(dude.killCount).toEqual 6

    it "Conditional yielding infinite loop", ->
      aether = new Aether yieldConditionally: true, simpleLoops: true
      code = """
        var x = 0;
        while (true) {
          x++;
        }
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f()
      for i in [0..100]
        expect(gen.next().done).toEqual false

    it "Conditional yielding empty loop", ->
      aether = new Aether yieldConditionally: true, simpleLoops: true
      dude =
        killCount: 0
        slay: ->
          @killCount += 1
          aether._shouldYield = true
        getKillCount: -> return @killCount
      code = """
        var x = 0;
        while (true) {
          x++;
          if (x >= 3) break;
        }
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual true

    it "Conditional yielding mixed loops", ->
      aether = new Aether yieldConditionally: true, simpleLoops: true
      dude =
        killCount: 0
        slay: ->
          @killCount += 1
          aether._shouldYield = true
        getKillCount: -> return @killCount
      code = """
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
        }
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude
      for i in [1..5]
        expect(gen.next().done).toEqual false
        expect(dude.killCount).toEqual i
      for i in [1..10]
        expect(gen.next().done).toEqual false
        expect(dude.killCount).toEqual 5
      for i in [6..15]
        expect(gen.next().done).toEqual false
        expect(dude.killCount).toEqual i
      expect(gen.next().done).toEqual false
      expect(dude.killCount).toEqual 16
      expect(gen.next().done).toEqual true
      expect(dude.killCount).toEqual 16

    it "Conditional yielding nested loops", ->
      aether = new Aether yieldConditionally: true, simpleLoops: true
      dude =
        killCount: 0
        slay: ->
          @killCount += 1
          aether._shouldYield = true
        getKillCount: -> return @killCount
      code = """
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
        }
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude

      # NOTE: keep in mind no-yield loops break before invisible automatic yield

      # outer auto yield, inner yield
      for i in [1..3]
        for j in [1..2]
          expect(gen.next().done).toEqual false
          expect(dude.killCount).toEqual (i - 1) * 2 + j
        expect(gen.next().done).toEqual false if i < 3
      expect(dude.killCount).toEqual 6

      # outer yield, inner auto yield
      killOffset = dude.killCount
      for i in [1..5]
        for j in [1..3]
          expect(gen.next().done).toEqual false
        expect(gen.next().done).toEqual false
        expect(dude.killCount).toEqual i + killOffset
      expect(dude.killCount).toEqual 6 + 5

      # outer and inner auto yield
      killOffset = dude.killCount
      for i in [1..7]
        for j in [1..5]
          expect(gen.next().done).toEqual false
          expect(dude.killCount).toEqual killOffset
        expect(gen.next().done).toEqual false if i < 7
      expect(dude.killCount).toEqual 6 + 5 + 0

      # outer and inner yields
      killOffset = dude.killCount
      for i in [1..8]
        expect(gen.next().done).toEqual false
        for j in [1..9]
          expect(gen.next().done).toEqual false
          expect(dude.killCount).toEqual (i - 1) * 9 + i + j + killOffset
      expect(dude.killCount).toEqual 6 + 5 + 0 + 80

      expect(gen.next().done).toEqual true
      expect(dude.killCount).toEqual 91

    it "Automatic yielding", ->
      aether = new Aether yieldAutomatically: true, simpleLoops: true
      dude =
        killCount: 0
        slay: -> @killCount += 1
        getKillCount: -> return @killCount
      code = """
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

      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude
      while (true)
        if gen.next().done then break
      expect(dude.killCount).toEqual 6

  describe "whileTrueAutoYield", ->
    it "while (true) {}", ->
      code = """
      var total = 0
      while (true) { total += 1; if (total >= 12) {break;}}
      return total
      """
      aether = new Aether language: "javascript", whileTrueAutoYield: true
      aether.transpile(code)
      expect(aether.run()).toEqual(12)

    it "Conditional yielding", ->
      aether = new Aether yieldConditionally: true, whileTrueAutoYield: true
      dude =
        killCount: 0
        slay: ->
          @killCount += 1
          aether._shouldYield = true
        getKillCount: -> return @killCount
      code = """
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
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude
      for i in [1..6]
        expect(gen.next().done).toEqual false
        expect(dude.killCount).toEqual i
      expect(gen.next().done).toEqual true
      expect(dude.killCount).toEqual 6

    it "Conditional yielding infinite loop", ->
      aether = new Aether yieldConditionally: true, whileTrueAutoYield: true
      code = """
        var x = 0;
        while (true) {
          x++;
        }
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f()
      for i in [0..100]
        expect(gen.next().done).toEqual false

    it "Conditional yielding empty loop", ->
      aether = new Aether yieldConditionally: true, whileTrueAutoYield: true
      dude =
        killCount: 0
        slay: ->
          @killCount += 1
          aether._shouldYield = true
        getKillCount: -> return @killCount
      code = """
        var x = 0;
        while (true) {
          x++;
          if (x >= 3) break;
        }
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual true

    xit "Conditional yielding mixed loops", ->
      aether = new Aether yieldConditionally: true, whileTrueAutoYield: true
      dude =
        killCount: 0
        slay: ->
          @killCount += 1
          aether._shouldYield = true
        getKillCount: -> return @killCount
      code = """
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
        }
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude
      for i in [1..5]
        expect(gen.next().done).toEqual false
        expect(dude.killCount).toEqual i
      for i in [1..10]
        expect(gen.next().done).toEqual false
        expect(dude.killCount).toEqual 5
      for i in [6..15]
        expect(gen.next().done).toEqual false
        expect(dude.killCount).toEqual i
      expect(gen.next().done).toEqual false
      expect(dude.killCount).toEqual 16
      expect(gen.next().done).toEqual true
      expect(dude.killCount).toEqual 16

    it "Conditional yielding nested loops", ->
      aether = new Aether yieldConditionally: true, whileTrueAutoYield: true
      dude =
        killCount: 0
        slay: ->
          @killCount += 1
          aether._shouldYield = true
        getKillCount: -> return @killCount
      code = """
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
        }
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude

      # NOTE: keep in mind no-yield loops break before invisible automatic yield

      # outer auto yield, inner yield
      for i in [1..3]
        for j in [1..2]
          expect(gen.next().done).toEqual false
          expect(dude.killCount).toEqual (i - 1) * 2 + j
        expect(gen.next().done).toEqual false if i < 3
      expect(dude.killCount).toEqual 6

      # outer yield, inner auto yield
      killOffset = dude.killCount
      for i in [1..5]
        for j in [1..3]
          expect(gen.next().done).toEqual false
        expect(gen.next().done).toEqual false
        expect(dude.killCount).toEqual i + killOffset
      expect(dude.killCount).toEqual 6 + 5

      # outer and inner auto yield
      killOffset = dude.killCount
      for i in [1..7]
        for j in [1..5]
          expect(gen.next().done).toEqual false
          expect(dude.killCount).toEqual killOffset
        expect(gen.next().done).toEqual false if i < 7
      expect(dude.killCount).toEqual 6 + 5 + 0

      # outer and inner yields
      killOffset = dude.killCount
      for i in [1..8]
        expect(gen.next().done).toEqual false
        for j in [1..9]
          expect(gen.next().done).toEqual false
          expect(dude.killCount).toEqual (i - 1) * 9 + i + j + killOffset
      expect(dude.killCount).toEqual 6 + 5 + 0 + 80

      expect(gen.next().done).toEqual true
      expect(dude.killCount).toEqual 91

    it "Automatic yielding", ->
      aether = new Aether yieldAutomatically: true, whileTrueAutoYield: true
      dude =
        killCount: 0
        slay: -> @killCount += 1
        getKillCount: -> return @killCount
      code = """
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

      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude
      while (true)
        if gen.next().done then break
      expect(dude.killCount).toEqual 6



