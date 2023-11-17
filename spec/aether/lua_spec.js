/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const Aether = require('../aether');
const lodash = require('lodash');

const language = 'lua';
let aether = new Aether({language});

const luaEval = function(code, that) {
  aether.reset();
  aether.transpile(code);
  return aether.run();
};

describe(`${language} Test suite`, function() {
  describe("Basics", function() {
    it("return 1000", () => expect(luaEval(`\

return 1000
\
`)).toEqual(1000));
    it("simple if", () => expect(luaEval(`\
if false then return 2000 end
return 1000\
`)).toBe(1000));

    it("multiple elif", () => expect(luaEval(`\
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
end\
`)).toBe(5));

    it("mathmetics order", function() {
      const code = `\
return (2*2 + 2/2 - 2*2/2)\
`;
      aether.transpile(code);
      return expect(aether.run()).toBe(3);
    });

    it("fibonacci function", () => expect(luaEval(`\
function fib(n)
if n < 2 then return n
else return fib(n - 1) + fib(n - 2) end
end
chupacabra = fib(10)
return chupacabra\
`)).toEqual(55));

    it("for loop", () => expect(luaEval(`\
data = {4, 2, 65, 7}
total = 0
for k,d in pairs(data) do
total = total + d
end
return total\
`)).toBe(78));

    it("bubble sort", function() {
      const code = `\
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
return isSorted(data)\
`;
      aether.transpile(code);
      return expect(aether.run()).toBe(true);
    });

    return it("dictionary", function() {
      const code = `\
d = {p1='prop1'}
return d['p1']\
`;
      aether.transpile(code);
      return expect(aether.run()).toBe('prop1');
    });
  });

  describe("Usage", function() {
    it("self.doStuff via thisValue param", function() {
      const history = [];
      const log = function(s) {
        expect(s).toEqual("hello");
        return history.push(s);
      };
      const thisValue = {say: log};
      thisValue.moveDown = function() {
        expect(this).toEqual(thisValue);
        return history.push('moveDown');
      };

      const aetherOptions = {
        language
      };
      aether = new Aether(aetherOptions);
      const code = `\
self:moveDown()
self:say('hello')\
`;
      aether.transpile(code);
      const method = aether.createMethod(thisValue);
      aether.run(method);
      return expect(history).toEqual(['moveDown', 'hello']);
    });

    it("Math is fun?", function() {
      const thisValue = {};
      const aetherOptions = {
        language
      };
      aether = new Aether(aetherOptions);
      const code = `\
return math.abs(-3) == 3\
`;
      aether.transpile(code);
      const method = aether.createMethod(thisValue);
      return expect(aether.run(method)).toEqual(true);
    });

    return it("self.getItems", function() {
      const history = [];
      const getItems = () => [{'pos':1}, {'pos':4}, {'pos':3}, {'pos':5}];
      const move = i => history.push(i);
      const thisValue = {getItems, move};
      const aetherOptions = {
        language
      };
      aether = new Aether(aetherOptions);
      const code = `\
local items = self.getItems()
for k,item in pairs(items) do
  self.move(item['pos'])
end\
`;
      aether.transpile(code);
      const method = aether.createMethod(thisValue);
      aether.run(method);
      return expect(history).toEqual([1, 4, 3, 5]);
    });
  });

  describe("Runtime problems", () => it("Should capture runtime problems", function() {
    // 0123456789012345678901234567
    const code = `\
self:explode()
self:exploooode()  -- should error
self:explode()\
`;
    const explosions = [];
    const thisValue = {explode() { return explosions.push('explosion!'); }};
    const aetherOptions = {language};
    aether = new Aether(aetherOptions);
    aether.transpile(code);
    const method = aether.createMethod(thisValue);
    aether.run(method);
    expect(explosions).toEqual(['explosion!']);
    expect(aether.problems.errors.length).toEqual(1);
    const problem = aether.problems.errors[0];
    expect(problem.type).toEqual('runtime');
    expect(problem.level).toEqual('error');
    expect(problem.message).toMatch(/exploooode/);
    expect(problem.range != null ? problem.range.length : undefined).toEqual(2);
    const [start, end] = Array.from(problem.range);
    expect(start.ofs).toEqual(15);
    expect(start.row).toEqual(1);
    expect(start.col).toEqual(0);
    expect(end.ofs).toEqual(32);
    expect(end.row).toEqual(1);
    expect(end.col).toEqual(17);
    return expect(problem.message).toMatch(/Line 2/);
  }));


  return describe("Yielding", function() {
    it("Conditional yielding returns are correct", function() {
      aether = new Aether({language: "lua", yieldConditionally: true});
      let result = null;
      const dude = {
        killCount: 0,
        say(v) { return result = v; },
        slay() {
          this.killCount += 1;
          return aether._shouldYield = true;
        },
        getKillCount() { return this.killCount; }
      };
      const code = `\
function add(a,b) return a + b end
self:slay()
self:slay()
local tosay = add(2,3)
self:say(tosay)
self:slay()\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);

      for (let i = 1; i <= 3; i++) {
        expect(gen.next().done).toEqual(false);
        expect(dude.killCount).toEqual(i);
      }
      expect(gen.next().done).toEqual(true);
      return expect(result).toEqual(5);
    });

    return it("Likes Simple Loops", function() {
      aether = new Aether({language: "lua", yieldConditionally: true, simpleLoops: true});
      const result = null;
      const dude =
        {x: 0};
      const code = `\
while true do
   self.x = self.x + 1
end\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);

      for (let i = 1; i <= 3; i++) {
        expect(gen.next().done).toEqual(false);
        expect(dude.x).toEqual(i);
      }

      return expect(gen.next().done).toEqual(false);
    });
  });
});
