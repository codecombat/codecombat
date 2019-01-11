Aether = require '../aether'

list = (x) => x

describe "Python test suite", ->
  describe "Basics", ->
    aether = new Aether language: "python"
    it "return 1000", ->
      code = """
      return 1000
      """
      aether.transpile(code)
      expect(aether.run()).toEqual 1000

    it "simple if", ->
      code = """
      if False: return 2000
      return 1000
      """
      aether.transpile(code)
      expect(aether.run()).toBe(1000)

    it "multiple elif", ->
      code = """
      x = 4
      if x == 2:
        x += 1
        return '2'
      elif x == 44564:
        x += 1
        return '44564'
      elif x == 4:
        x += 1
        return '4'
      """
      aether.transpile(code)
      expect(aether.run()).toBe('4')

    it "mathmetics order", ->
      code = """
      return (2*2 + 2/2 - 2*2/2)
      """
      aether.transpile(code)
      expect(aether.run()).toBe(3)

    it "fibonacci function", ->
      code = """
      def fib(n):
        if n < 2: return n
        else: return fib(n - 1) + fib(n - 2)
      chupacabra = fib(6)
      return chupacabra
      """
      aether.transpile(code)
      expect(aether.run()).toBe(8)

    it "for loop", ->
      code = """
      data = [4, 2, 65, 7]
      total = 0
      for d in data:
        total += d
      return total
      """
      aether.transpile(code)
      expect(aether.run()).toBe(78)

    it "bubble sort", ->
      code = """
      import random
      def createShuffled(n):
        r = n * 10 + 1
        shuffle = []
        for i in range(n):
          item = int(r * random.random())
          shuffle.append(item)
        return shuffle

      def bubbleSort(data):
        sorted = False
        while not sorted:
          sorted = True
          for i in range(len(data) - 1):
            if data[i] > data[i + 1]:
              t = data[i]
              data[i] = data[i + 1]
              data[i + 1] = t
              sorted = False
        return data

      def isSorted(data):
        for i in range(len(data) - 1):
          if data[i] > data[i + 1]:
            return False
        return True

      data = createShuffled(10)
      bubbleSort(data)
      return isSorted(data)
      """
      aether.transpile(code)
      expect(aether.run()).toBe(true)

    it "dictionary", ->
      code = """
      d = {'p1': 'prop1'}
      return d['p1']
      """
      aether.transpile(code)
      expect(aether.run()).toBe('prop1')

    it "class", ->
      code = """
      class MyClass:
        i = 123
        def __init__(self, i):
          self.i = i
        def f(self):
          return self.i
      x = MyClass(456)
      return x.f()
      """
      aether.transpile(code)
      expect(aether.run()).toEqual(456)

    it "L[0:2]", ->
      code = """
      L = [1, 45, 6, -9]
      return L[0:2]
      """
      aether.transpile(code)
      expect(aether.run()).toEqual(list([1, 45]))

    it "L[f(2)::9 - (2 * 5)]", ->
      code = """
      def f(x):
        return x
      L = [0, 1, 2, 3, 4]
      return L[f(2)::9 - (2 * 5)]
      """
      aether.transpile(code)
      expect(aether.run()).toEqual(list([2, 1, 0]))

    it "T[-1:-3:-1]", ->
      code = """
      T = (0, 1, 2, 3, 4)
      return T[-1:-3:-1]
      """
      aether.transpile(code)
      expect(aether.run()).toEqual(list([4, 3]))

    it "[str(round(pi, i)) for i in range(1, 6)]", ->
      code = """
      pi = 3.1415926
      L = [str(round(pi, i)) for i in range(1, 6)]
      return L
      """
      aether.transpile(code)
      expect(aether.run()).toEqual(list(['3.1', '3.14', '3.142', '3.1416', '3.14159']))

    it "[(x*2, y) for x in range(4) if x > 1 for y in range(2)]", ->
      code = """
      L = [(x*2, y) for x in range(4) if x > 1 for y in range(2)]
      return L[1]
      """
      aether.transpile(code)
      expect(aether.run()).toEqual(list([4, 1]))

    it "range(0, 10, 4)", ->
      code = """
      return range(0, 10, 4)
      """
      aether.transpile(code)
      expect(aether.run()).toEqual(list([0, 4, 8]))

    it "sequence operations", ->
      code = """
      a = [1]
      b = a + [2]
      b *= 2
      return b
      """
      aether.transpile(code)
      expect(aether.run()).toEqual(list([1, 2, 1, 2]))

    it "default and keyword fn arguments", ->
      code = """
      def f(a=4, b=7, c=10):
        return a + b + c
      return f(4, c=2, b=1)
      """
      aether.transpile(code)
      expect(aether.run()).toEqual(7)

    it "*args and **kwargs", ->
      code = """
      def f(x, y=5, z=8, *a, **b):
        return x + y + z + sum(a) + sum([b[k] for k in b])
      return f(1, 2, 3, 4, 5, a=10, b=100)
      """
      aether.transpile(code)
      expect(aether.run()).toEqual(125)

    it "Protected API returns Python list", ->
      code ="""
        items = self.getItems()
        if items._isPython:
           return items.count(3)
        return 'not a Python object'
      """
      aether = new Aether language: "python", protectAPI: true
      aether.transpile code
      selfValue = {getItems: -> [3, 3, 4, 3, 5, 6, 3]}
      method = aether.createMethod selfValue
      expect(aether.run(method)).toEqual(4)

    xit "Protected API returns Python dict", ->
      code ="""
        items = self.getItems()
        if items._isPython:
            return items.length
        return 'not a Python object'
      """
      aether = new Aether language: "python", protectAPI: true
      aether.transpile code
      selfValue = {getItems: -> {'name': 'Bob', 'shortName': true}}
      method = aether.createMethod selfValue
      expect(aether.run(method)).toEqual(2)

    it "Pass Python arguments to inner functions", ->
      code ="""
        def f(d, l):
          return d._isPython and l._isPython
        return f({'p1': 'Bob'}, ['Python', 'is', 'fun.', True])
      """
      aether = new Aether language: "python", protectAPI: true
      aether.transpile code
      expect(aether.run()).toEqual(true)

    it "Empty if", ->
      code = """
if True:
x = 5
      """
      aether = new Aether language: "python", simpleLoops: true
      aether.transpile code
      expect(aether.problems.errors.length).toEqual(1)
      expect(aether.problems.errors[0].type).toEqual('transpile')
      expect(aether.problems.errors[0].message).toEqual("Empty if statement. Put 4 spaces in front of statements inside the if statement.")

    it "convertToNativeType", ->
      globals =
        foo: ->
          o = p1: 34, p2: 'Bob'
          Object.defineProperty o, 'health', value: 42
      code = """
        myObj = self.foo()
        return myObj.health
      """
      aether = new Aether language: "python", simpleLoops: true, yieldConditionally: true
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply globals
      result = gen.next()
      expect(aether.problems.errors.length).toEqual(0)
      expect(result.value).toEqual(42)

  describe "Conflicts", ->
    it "doesn't interfere with type property", ->
      code = """
      d = {'type': 'merino wool'}
      return d['type']
      """
      aether = new Aether language: "python", protectAPI: true
      aether.transpile(code)
      expect(aether.run()).toBe('merino wool')

  describe "Usage", ->
    it "self.doStuff via thisValue param", ->
      history = []
      log = (s) -> history.push s
      moveDown = -> history.push 'moveDown'
      thisValue = {say: log, moveDown: moveDown}
      aetherOptions = {
        language: 'python'
      }
      aether = new Aether aetherOptions
      code = """
      self.moveDown()
      self.say('hello')
      """
      aether.transpile code
      method = aether.createMethod thisValue
      aether.run method
      expect(history).toEqual(['moveDown', 'hello'])

    it "Math is fun?", ->
      thisValue = {}
      aetherOptions = {
        language: 'python'
      }
      aether = new Aether aetherOptions
      code = """
      return Math.abs(-3) == abs(-3)
      """
      aether.transpile code
      method = aether.createMethod thisValue
      expect(aether.run(method)).toEqual(true)

    it "self.getItems()", ->
      history = []
      getItems = -> [{'pos':1}, {'pos':4}, {'pos':3}, {'pos':5}]
      move = (i) -> history.push i
      thisValue = {getItems: getItems, move: move}
      aetherOptions = {
        language: 'python'
      }
      code = """
      items = self.getItems()
      for item in items:
        self.move(item['pos'])
      """
      aether = new Aether aetherOptions
      aether.transpile code
      method = aether.createMethod thisValue
      aether.run method
      expect(history).toEqual([1, 4, 3, 5])

  xdescribe "parseDammit! & Ranges", ->
    aether = new Aether language: "python"
    xit "Bad indent", ->
      code = """
      def fn():
        x = 45
          x += 5
        return x
      return fn()
      """
      aether.transpile(code)
      result = aether.run()
      expect(aether.problems.errors.length).toEqual(1)
      expect(/Unexpected indent/.test(aether.problems.errors[0].message)).toBe(true)
      expect(aether.problems.errors[0].range).toEqual([ { ofs : 21, row : 2, col : 2 }, { ofs : 23, row : 2, col : 4 } ])
      expect(result).toEqual(50)

    xit "Bad indent after comment", ->
      # https://github.com/codecombat/aether/issues/116
      code = """
      def fn():
        x = 45
        # Bummer
          x += 5
        return x
      return fn()
      """
      aether.transpile(code)
      result = aether.run()
      expect(aether.problems.errors.length).toEqual(1)
      expect(/Unexpected indent/.test(aether.problems.errors[0].message)).toBe(true)
      expect(aether.problems.errors[0].range).toEqual([ { ofs : 32, row : 3, col : 2 }, { ofs : 34, row : 3, col : 4 } ])
      expect(result).toEqual(50)

    xit "Transpile error, missing )", ->
      code = """
      def fn():
        return 45
      x = fn(
      return x
      """
      aether.transpile(code)
      expect(aether.problems.errors.length).toEqual(1)
      expect(/Unexpected token/.test(aether.problems.errors[0].message)).toBe(true)
      expect(aether.problems.errors[0].range).toEqual([ { ofs : 29, row : 2, col : 7 }, { ofs : 30, row : 2, col : 8 } ])
      result = aether.run()
      expect(result).toEqual(45)

    xit "Missing self: x() row 0", ->
      code = """x()"""
      aether.transpile(code)
      expect(aether.problems.errors.length).toEqual(1)
      expect(aether.problems.errors[0].message).toEqual("Missing `self` keyword; should be `self.x`.")
      expect(aether.problems.errors[0].range).toEqual([ { ofs: 0, row: 0, col: 0 }, { ofs: 3, row: 0, col: 3 } ])

    xit "Missing self: x() row 1", ->
      code = """
      y = 5
      x()
      """
      aether.transpile(code)
      expect(aether.problems.errors.length).toEqual(1)
      expect(aether.problems.errors[0].message).toEqual("Missing `self` keyword; should be `self.x`.")
      expect(aether.problems.errors[0].range).toEqual([ { ofs: 6, row: 1, col: 0 }, { ofs: 9, row: 1, col: 3 } ])

    xit "Missing self: x() row 3", ->
      code = """
      y = 5
      s = 'some other stuff'
      if y is 5:
        x()
      """
      aether.transpile(code)
      expect(aether.problems.errors.length).toEqual(1)
      expect(aether.problems.errors[0].message).toEqual("Missing `self` keyword; should be `self.x`.")
      expect(aether.problems.errors[0].range).toEqual([ { ofs: 42, row: 3, col: 2 }, { ofs: 45, row: 3, col: 5 } ])

    it "self.getItems missing parentheses", ->
      code = """
      self.getItems
      """
      aether = new Aether language: 'python', problemContext: thisMethods: ['getItems']
      aether.transpile code
      aether.run()
      expect(aether.problems.errors.length).toEqual(1)
      expect(aether.problems.errors[0].message).toEqual('self.getItems has no effect. It needs parentheses: self.getItems()')
      expect(aether.problems.errors[0].range).toEqual([ { ofs : 0, row : 0, col : 0 }, { ofs : 13, row : 0, col : 13 } ])

    it "self.getItems missing parentheses row 1", ->
      code = """
      x = 5
      self.getItems
      """
      aether = new Aether language: 'python', problemContext: thisMethods: ['getItems']
      aether.transpile code
      aether.run()
      expect(aether.problems.errors.length).toEqual(1)
      expect(aether.problems.errors[0].message).toEqual('self.getItems has no effect. It needs parentheses: self.getItems()')
      expect(aether.problems.errors[0].range).toEqual([ { ofs : 6, row : 1, col : 0 }, { ofs : 19, row : 1, col : 13 } ])

    it "Incomplete string", ->
      code = """
      s = 'hi
      return s
      """
      aether.transpile(code)
      expect(aether.problems.errors.length).toEqual(1)
      expect(/Unterminated string constant/.test(aether.problems.errors[0].message)).toBe(true)
      expect(aether.problems.errors[0].range).toEqual([ { ofs : 4, row : 0, col : 4 }, { ofs : 7, row : 0, col : 7 } ])
      result = aether.run()
      expect(result).toEqual('hi')

    it "Runtime ReferenceError", ->
      code = """
      x = 5
      y = x + z
      """
      aether.transpile(code)
      aether.run()
      expect(aether.problems.errors.length).toEqual(1)
      expect(/ReferenceError/.test(aether.problems.errors[0].message)).toBe(true)
      expect(aether.problems.errors[0].range).toEqual([ { ofs : 14, row : 1, col : 8 }, { ofs : 15, row : 1, col : 9 } ])

  xdescribe "Simple loop", ->
    it "loop:", ->
      code = """
      total = 0
      loop:
        total += 1
        if total is 10: break;
      return total
      """
      aether = new Aether language: "python", simpleLoops: true
      aether.transpile(code)
      expect(aether.run()).toEqual(10)

    it "loop : (whitespace)", ->
      code = """
      total = 0
      loop  :
        total += 1
        if total is 10: break;
      return total
      """
      aether = new Aether language: "python", simpleLoops: true
      aether.transpile(code)
      expect(aether.run()).toEqual(10)

    it "loop : (no :)", ->
      code = """
      total = 0
      loop
        total += 1
        if total is 10: break;
      return total
      """
      aether = new Aether language: "python", simpleLoops: true
      aether.transpile(code)
      expect(aether.problems.warnings.length).toEqual(1)
      expect(aether.problems.warnings[0].type).toEqual('transpile')
      expect(aether.problems.warnings[0].message).toEqual("You are missing a ':' after 'loop'. Try `loop:`")
      expect(aether.run()).toEqual(10)


    xit "one line", ->
      # Blocked by https://github.com/differentmatt/filbert/issues/41
      code = """
      total = 0
      loop: total += 12; break;
      return total
      """
      aether = new Aether language: "python", simpleLoops: true
      aether.transpile(code)
      expect(aether.run()).toEqual(12)

    xit "loop  :", ->
      # Blocked by https://github.com/codecombat/aether/issues/108
      code = """
      total = 0
      loop  :
        total += 23;
        break;
      return total
      """
      aether = new Aether language: "python", simpleLoops: true
      aether.transpile(code)
      expect(aether.run()).toEqual(23)

    it "Conditional yielding", ->
      aether = new Aether language: "python", yieldConditionally: true, simpleLoops: true
      dude =
        killCount: 0
        slay: ->
          @killCount += 1
          aether._shouldYield = true
        getKillCount: -> return @killCount
      code = """
        while True:
          self.slay();
          break;
        loop:
          self.slay();
          if self.getKillCount() >= 5:
            break;
        while True:
          self.slay();
          break;
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude

      for i in [1..6]
        expect(gen.next().done).toEqual false
        expect(dude.killCount).toEqual i
      expect(gen.next().done).toEqual true
      expect(dude.killCount).toEqual 6

    it "Conditional yielding empty loop", ->
      aether = new Aether language: "python", yieldConditionally: true, simpleLoops: true
      dude =
        killCount: 0
        slay: ->
          @killCount += 1
          aether._shouldYield = true
        getKillCount: -> return @killCount
      code = """
        x = 0
        loop:
          x += 1
          if x >= 3:
            break
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual true

    it "Conditional yielding mixed loops", ->
      aether = new Aether language: "python", yieldConditionally: true, simpleLoops: true
      dude =
        killCount: 0
        slay: ->
          @killCount += 1
          aether._shouldYield = true
        getKillCount: -> return @killCount
      code = """
        loop:
          self.slay()
          if self.getKillCount() >= 5:
            break
        x = 0
        loop:
          x += 1
          if x > 10:
            break
        loop:
          self.slay()
          if self.getKillCount() >= 15:
            break
        while True:
          self.slay()
          break
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
      aether = new Aether language: "python", yieldConditionally: true, simpleLoops: true
      dude =
        killCount: 0
        slay: ->
          @killCount += 1
          aether._shouldYield = true
        getKillCount: -> return @killCount
      code = """
        # outer auto yield, inner yield
        x = 0
        loop:
          y = 0
          loop:
            self.slay()
            y += 1
            if y >= 2:
              break
          x += 1
          if x >= 3:
            break

        # outer yield, inner auto yield
        x = 0
        loop:
          self.slay()
          y = 0
          loop:
            y += 1
            if y >= 4:
              break
          x += 1
          if x >= 5:
            break

        # outer and inner auto yield
        x = 0
        loop:
          y = 0
          loop:
            y += 1
            if y >= 6:
              break
          x += 1
          if x >= 7:
            break

        # outer and inner yields
        x = 0
        loop:
          self.slay()
          y = 0
          loop:
            self.slay()
            y += 1
            if y >= 9:
              break
          x += 1
          if x >= 8:
            break
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude

      # NOTE: auto yield loops break before invisible automatic yield

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

    it "Empty loop", ->
      code = """
loop:
x = 5
      """
      aether = new Aether language: "python", simpleLoops: true
      aether.transpile code
      expect(aether.problems.warnings.length).toEqual(1)
      expect(aether.problems.warnings[0].type).toEqual('transpile')
      expect(aether.problems.warnings[0].message).toEqual("Empty loop. Put 4 spaces in front of statements inside loops.")

    # TODO: simple loop in a function
    # TODO: blocked by https://github.com/codecombat/aether/issues/48

  xdescribe "whileTrueAutoYield", ->
    it "while True: no yieldConditionally", ->
      code = """
      total = 0
      while True:
        total += 1
        if total is 10: break;
      return total
      """
      aether = new Aether language: "python", whileTrueAutoYield: true
      aether.transpile(code)
      expect(aether.run()).toEqual(10)

    it "Conditional yielding and simpleLoops", ->
      aether = new Aether language: "python", yieldConditionally: true, whileTrueAutoYield: true, simpleLoops: true
      dude = {}
      code = """
        x = 0
        while True:
          x += 1
          if x >= 3:
            break
        x = 0
        loop:
          x += 1
          if x >= 3:
            break
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual true

    it "Conditional yielding empty loop", ->
      aether = new Aether language: "python", yieldConditionally: true, whileTrueAutoYield: true
      dude = {}
      code = """
        x = 0
        while True:
          x += 1
          if x >= 3:
            break
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual false
      expect(gen.next().done).toEqual true

    it "Conditional yielding mixed loops", ->
      aether = new Aether language: "python", yieldConditionally: true, whileTrueAutoYield: true
      dude =
        killCount: 0
        slay: ->
          @killCount += 1
          aether._shouldYield = true
        getKillCount: -> return @killCount
      code = """
        while True:
          self.slay()
          if self.getKillCount() >= 5:
            break
        x = 0
        while True:
          x += 1
          if x > 10:
            break
        while True:
          self.slay()
          if self.getKillCount() >= 15:
            break
        while 4 is 4:
          self.slay()
          break
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
      aether = new Aether language: "python", yieldConditionally: true, whileTrueAutoYield: true
      dude =
        killCount: 0
        slay: ->
          @killCount += 1
          aether._shouldYield = true
        getKillCount: -> return @killCount
      code = """
        # outer auto yield, inner yield
        x = 0
        while True:
          y = 0
          while True:
            self.slay()
            y += 1
            if y >= 2:
              break
          x += 1
          if x >= 3:
            break

        # outer yield, inner auto yield
        x = 0
        while True:
          self.slay()
          y = 0
          while True:
            y += 1
            if y >= 4:
              break
          x += 1
          if x >= 5:
            break

        # outer and inner auto yield
        x = 0
        while True:
          y = 0
          while True:
            y += 1
            if y >= 6:
              break
          x += 1
          if x >= 7:
            break

        # outer and inner yields
        x = 0
        while True:
          self.slay()
          y = 0
          while True:
            self.slay()
            y += 1
            if y >= 9:
              break
          x += 1
          if x >= 8:
            break
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude

      # NOTE: auto yield loops break before invisible automatic yield

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

    it "Empty loop", ->
      code = """
while True:
x = 5
      """
      aether = new Aether language: "python", whileTrueAutoYield: true
      aether.transpile code
      console.log JSON.stringify(aether.problems)
      expect(aether.problems.warnings.length).toEqual(1)
      expect(aether.problems.warnings[0].type).toEqual('transpile')
      expect(aether.problems.warnings[0].message).toEqual("Empty loop. Put 4 spaces in front of statements inside loops.")
