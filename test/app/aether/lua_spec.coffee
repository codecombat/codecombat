Aether = require '../aether'
lodash = require 'lodash'

language = 'lua'
aether = new Aether language: language

luaEval = (code, that) ->
  aether.reset()
  aether.transpile(code)
  return aether.run()

describe "#{language} Test suite", ->
  describe "Basics", ->
    it "return 1000", ->
      expect(luaEval("""

      return 1000

      """)).toEqual 1000
    it "simple if", ->
      expect(luaEval("""
      if false then return 2000 end
      return 1000
      """)).toBe(1000)

    it "multiple elif", ->
      expect(luaEval("""
      local x = 4
      if x == 2 then
        x = x + 1
        return '2'
      elseif x == 44564 then
        x = x + 1
        return '44564'
      elseif x == 4 then
        x = x + 1
        return x
      end
      """)).toBe(5)

    it "mathmetics order", ->
      code = """
      return (2*2 + 2/2 - 2*2/2)
      """
      aether.transpile(code)
      expect(aether.run()).toBe(3)

    it "fibonacci function", ->
      expect(luaEval("""
      function fib(n)
        if n < 2 then return n
        else return fib(n - 1) + fib(n - 2) end
      end
      chupacabra = fib(10)
      return chupacabra
      """)).toEqual 55

    it "for loop", ->
      expect(luaEval("""
      data = {4, 2, 65, 7}
      total = 0
      for k,d in pairs(data) do
        total = total + d
      end
      return total
      """)).toBe(78)

    it "bubble sort", ->
      code = """
      local function createShuffled(n)
        r = n * 10 + 1
        shuffle = {}
        for i=1,n do
          item = r * math.random()
          shuffle[#shuffle] = item
        end
        return shuffle
      end

      local function bubbleSort(data)
        sorted = false
        while not sorted do
          sorted = true
          for i=1,#data - 1 do
            if data[i] > data[i + 1] then
              t = data[i]
              data[i] = data[i + 1]
              data[i+1] = t
              sorted = false
            end
          end
        end
        return data
      end

      local function isSorted(data)
        for i=1,#data - 1 do
          if data[i] > data[i + 1] then
            return false
          end
        end
        return true
      end

      data = createShuffled(10)
      bubbleSort(data)
      return isSorted(data)
      """
      aether.transpile(code)
      expect(aether.run()).toBe(true)

    it "dictionary", ->
      code = """
      d = {p1='prop1'}
      return d['p1']
      """
      aether.transpile(code)
      expect(aether.run()).toBe('prop1')

  describe "Usage", ->
    it "self.doStuff via thisValue param", ->
      history = []
      log = (s) ->
        expect(s).toEqual "hello"
        history.push s
      thisValue = {say: log}
      thisValue.moveDown = () ->
        expect(this).toEqual thisValue
        history.push 'moveDown'

      aetherOptions = {
        language: language
      }
      aether = new Aether aetherOptions
      code = """
      self:moveDown()
      self:say('hello')
      """
      aether.transpile code
      method = aether.createMethod thisValue
      aether.run method
      expect(history).toEqual(['moveDown', 'hello'])

    it "Math is fun?", ->
      thisValue = {}
      aetherOptions = {
        language: language
      }
      aether = new Aether aetherOptions
      code = """
      return math.abs(-3) == 3
      """
      aether.transpile code
      method = aether.createMethod thisValue
      expect(aether.run(method)).toEqual(true)

    it "self.getItems", ->
      history = []
      getItems = () -> [{'pos':1}, {'pos':4}, {'pos':3}, {'pos':5}]
      move = (i) -> history.push i
      thisValue = {getItems: getItems, move: move}
      aetherOptions = {
        language: language
      }
      aether = new Aether aetherOptions
      code = """
      local items = self.getItems()
      for k,item in pairs(items) do
        self.move(item['pos'])
      end
      """
      aether.transpile code
      method = aether.createMethod thisValue
      aether.run method
      expect(history).toEqual([1, 4, 3, 5])

  describe "Runtime problems", ->
    it "Should capture runtime problems", ->
      # 0123456789012345678901234567
      code = """
        self:explode()
        self:exploooode()  -- should error
        self:explode()
      """
      explosions = []
      thisValue = explode: -> explosions.push 'explosion!'
      aetherOptions = language: language
      aether = new Aether aetherOptions
      aether.transpile code
      method = aether.createMethod thisValue
      aether.run method
      expect(explosions).toEqual(['explosion!'])
      expect(aether.problems.errors.length).toEqual 1
      problem = aether.problems.errors[0]
      expect(problem.type).toEqual 'runtime'
      expect(problem.level).toEqual 'error'
      expect(problem.message).toMatch /exploooode/
      expect(problem.range?.length).toEqual 2
      [start, end] = problem.range
      expect(start.ofs).toEqual 15
      expect(start.row).toEqual 1
      expect(start.col).toEqual 0
      expect(end.ofs).toEqual 32
      expect(end.row).toEqual 1
      expect(end.col).toEqual 17
      expect(problem.message).toMatch /Line 2/


  describe "Yielding", ->
    it "Conditional yielding returns are correct", ->
      aether = new Aether language: "lua", yieldConditionally: true
      result = null
      dude =
        killCount: 0
        say: (v) -> result = v
        slay: ->
          @killCount += 1
          aether._shouldYield = true
        getKillCount: -> return @killCount
      code = """
        function add(a,b) return a + b end
        self:slay()
        self:slay()
        local tosay = add(2,3)
        self:say(tosay)
        self:slay()
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude

      for i in [1..3]
        expect(gen.next().done).toEqual false
        expect(dude.killCount).toEqual i
      expect(gen.next().done).toEqual true
      expect(result).toEqual 5

    it "Likes Simple Loops", ->
      aether = new Aether language: "lua", yieldConditionally: true, simpleLoops: true
      result = null
      dude =
        x: 0
      code = """
        while true do
           self.x = self.x + 1
        end
      """
      aether.transpile code
      f = aether.createFunction()
      gen = f.apply dude

      for i in [1..3]
        expect(gen.next().done).toEqual false
        expect(dude.x).toEqual i

      expect(gen.next().done).toEqual false
