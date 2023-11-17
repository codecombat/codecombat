/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const Aether = require('../aether');

const list = x => x;

describe("Python test suite", function() {
  describe("Basics", function() {
    let aether = new Aether({language: "python"});
    it("return 1000", function() {
      const code = `\
return 1000\
`;
      aether.transpile(code);
      return expect(aether.run()).toEqual(1000);
    });

    it("simple if", function() {
      const code = `\
if False: return 2000
return 1000\
`;
      aether.transpile(code);
      return expect(aether.run()).toBe(1000);
    });

    it("multiple elif", function() {
      const code = `\
x = 4
if x == 2:
  x += 1
  return '2'
elif x == 44564:
  x += 1
  return '44564'
elif x == 4:
  x += 1
  return '4'\
`;
      aether.transpile(code);
      return expect(aether.run()).toBe('4');
    });

    it("mathmetics order", function() {
      const code = `\
return (2*2 + 2/2 - 2*2/2)\
`;
      aether.transpile(code);
      return expect(aether.run()).toBe(3);
    });

    it("fibonacci function", function() {
      const code = `\
def fib(n):
  if n < 2: return n
  else: return fib(n - 1) + fib(n - 2)
chupacabra = fib(6)
return chupacabra\
`;
      aether.transpile(code);
      return expect(aether.run()).toBe(8);
    });

    it("for loop", function() {
      const code = `\
data = [4, 2, 65, 7]
total = 0
for d in data:
  total += d
return total\
`;
      aether.transpile(code);
      return expect(aether.run()).toBe(78);
    });

    it("bubble sort", function() {
      const code = `\
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
return isSorted(data)\
`;
      aether.transpile(code);
      return expect(aether.run()).toBe(true);
    });

    it("dictionary", function() {
      const code = `\
d = {'p1': 'prop1'}
return d['p1']\
`;
      aether.transpile(code);
      return expect(aether.run()).toBe('prop1');
    });

    it("class", function() {
      const code = `\
class MyClass:
  i = 123
  def __init__(self, i):
    self.i = i
  def f(self):
    return self.i
x = MyClass(456)
return x.f()\
`;
      aether.transpile(code);
      return expect(aether.run()).toEqual(456);
    });

    it("L[0:2]", function() {
      const code = `\
L = [1, 45, 6, -9]
return L[0:2]\
`;
      aether.transpile(code);
      return expect(aether.run()).toEqual(list([1, 45]));
    });

    it("L[f(2)::9 - (2 * 5)]", function() {
      const code = `\
def f(x):
  return x
L = [0, 1, 2, 3, 4]
return L[f(2)::9 - (2 * 5)]\
`;
      aether.transpile(code);
      return expect(aether.run()).toEqual(list([2, 1, 0]));
    });

    it("T[-1:-3:-1]", function() {
      const code = `\
T = (0, 1, 2, 3, 4)
return T[-1:-3:-1]\
`;
      aether.transpile(code);
      return expect(aether.run()).toEqual(list([4, 3]));
    });

    it("[str(round(pi, i)) for i in range(1, 6)]", function() {
      const code = `\
pi = 3.1415926
L = [str(round(pi, i)) for i in range(1, 6)]
return L\
`;
      aether.transpile(code);
      return expect(aether.run()).toEqual(list(['3.1', '3.14', '3.142', '3.1416', '3.14159']));
    });

    it("[(x*2, y) for x in range(4) if x > 1 for y in range(2)]", function() {
      const code = `\
L = [(x*2, y) for x in range(4) if x > 1 for y in range(2)]
return L[1]\
`;
      aether.transpile(code);
      return expect(aether.run()).toEqual(list([4, 1]));
    });

    it("range(0, 10, 4)", function() {
      const code = `\
return range(0, 10, 4)\
`;
      aether.transpile(code);
      return expect(aether.run()).toEqual(list([0, 4, 8]));
    });

    it("sequence operations", function() {
      const code = `\
a = [1]
b = a + [2]
b *= 2
return b\
`;
      aether.transpile(code);
      return expect(aether.run()).toEqual(list([1, 2, 1, 2]));
    });

    it("default and keyword fn arguments", function() {
      const code = `\
def f(a=4, b=7, c=10):
  return a + b + c
return f(4, c=2, b=1)\
`;
      aether.transpile(code);
      return expect(aether.run()).toEqual(7);
    });

    it("*args and **kwargs", function() {
      const code = `\
def f(x, y=5, z=8, *a, **b):
  return x + y + z + sum(a) + sum([b[k] for k in b])
return f(1, 2, 3, 4, 5, a=10, b=100)\
`;
      aether.transpile(code);
      return expect(aether.run()).toEqual(125);
    });

    it("Protected API returns Python list", function() {
      const code =`\
items = self.getItems()
if items._isPython:
   return items.count(3)
return 'not a Python object'\
`;
      aether = new Aether({language: "python", protectAPI: true});
      aether.transpile(code);
      const selfValue = {getItems() { return [3, 3, 4, 3, 5, 6, 3]; }};
      const method = aether.createMethod(selfValue);
      return expect(aether.run(method)).toEqual(4);
    });

    xit("Protected API returns Python dict", function() {
      const code =`\
items = self.getItems()
if items._isPython:
    return items.length
return 'not a Python object'\
`;
      aether = new Aether({language: "python", protectAPI: true});
      aether.transpile(code);
      const selfValue = {getItems() { return {'name': 'Bob', 'shortName': true}; }};
      const method = aether.createMethod(selfValue);
      return expect(aether.run(method)).toEqual(2);
    });

    it("Pass Python arguments to inner functions", function() {
      const code =`\
def f(d, l):
  return d._isPython and l._isPython
return f({'p1': 'Bob'}, ['Python', 'is', 'fun.', True])\
`;
      aether = new Aether({language: "python", protectAPI: true});
      aether.transpile(code);
      return expect(aether.run()).toEqual(true);
    });

    it("Empty if", function() {
      const code = `\
if True:
x = 5\
`;
      aether = new Aether({language: "python", simpleLoops: true});
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(1);
      expect(aether.problems.errors[0].type).toEqual('transpile');
      return expect(aether.problems.errors[0].message).toEqual("Empty if statement. Put 4 spaces in front of statements inside the if statement.");
    });

    return it("convertToNativeType", function() {
      const globals = {
        foo() {
          const o = {p1: 34, p2: 'Bob'};
          return Object.defineProperty(o, 'health', {value: 42});
        }
      };
      const code = `\
myObj = self.foo()
return myObj.health\
`;
      aether = new Aether({language: "python", simpleLoops: true, yieldConditionally: true});
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(globals);
      const result = gen.next();
      expect(aether.problems.errors.length).toEqual(0);
      return expect(result.value).toEqual(42);
    });
  });

  describe("Conflicts", () => it("doesn't interfere with type property", function() {
    const code = `\
d = {'type': 'merino wool'}
return d['type']\
`;
    const aether = new Aether({language: "python", protectAPI: true});
    aether.transpile(code);
    return expect(aether.run()).toBe('merino wool');
  }));

  describe("Usage", function() {
    it("self.doStuff via thisValue param", function() {
      const history = [];
      const log = s => history.push(s);
      const moveDown = () => history.push('moveDown');
      const thisValue = {say: log, moveDown};
      const aetherOptions = {
        language: 'python'
      };
      const aether = new Aether(aetherOptions);
      const code = `\
self.moveDown()
self.say('hello')\
`;
      aether.transpile(code);
      const method = aether.createMethod(thisValue);
      aether.run(method);
      return expect(history).toEqual(['moveDown', 'hello']);
    });

    it("Math is fun?", function() {
      const thisValue = {};
      const aetherOptions = {
        language: 'python'
      };
      const aether = new Aether(aetherOptions);
      const code = `\
return Math.abs(-3) == abs(-3)\
`;
      aether.transpile(code);
      const method = aether.createMethod(thisValue);
      return expect(aether.run(method)).toEqual(true);
    });

    return it("self.getItems()", function() {
      const history = [];
      const getItems = () => [{'pos':1}, {'pos':4}, {'pos':3}, {'pos':5}];
      const move = i => history.push(i);
      const thisValue = {getItems, move};
      const aetherOptions = {
        language: 'python'
      };
      const code = `\
items = self.getItems()
for item in items:
  self.move(item['pos'])\
`;
      const aether = new Aether(aetherOptions);
      aether.transpile(code);
      const method = aether.createMethod(thisValue);
      aether.run(method);
      return expect(history).toEqual([1, 4, 3, 5]);
    });
  });

  xdescribe("parseDammit! & Ranges", function() {
    let aether = new Aether({language: "python"});
    xit("Bad indent", function() {
      const code = `\
def fn():
  x = 45
    x += 5
  return x
return fn()\
`;
      aether.transpile(code);
      const result = aether.run();
      expect(aether.problems.errors.length).toEqual(1);
      expect(/Unexpected indent/.test(aether.problems.errors[0].message)).toBe(true);
      expect(aether.problems.errors[0].range).toEqual([ { ofs : 21, row : 2, col : 2 }, { ofs : 23, row : 2, col : 4 } ]);
      return expect(result).toEqual(50);
    });

    xit("Bad indent after comment", function() {
      // https://github.com/codecombat/aether/issues/116
      const code = `\
def fn():
  x = 45
  # Bummer
    x += 5
  return x
return fn()\
`;
      aether.transpile(code);
      const result = aether.run();
      expect(aether.problems.errors.length).toEqual(1);
      expect(/Unexpected indent/.test(aether.problems.errors[0].message)).toBe(true);
      expect(aether.problems.errors[0].range).toEqual([ { ofs : 32, row : 3, col : 2 }, { ofs : 34, row : 3, col : 4 } ]);
      return expect(result).toEqual(50);
    });

    xit("Transpile error, missing )", function() {
      const code = `\
def fn():
  return 45
x = fn(
return x\
`;
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(1);
      expect(/Unexpected token/.test(aether.problems.errors[0].message)).toBe(true);
      expect(aether.problems.errors[0].range).toEqual([ { ofs : 29, row : 2, col : 7 }, { ofs : 30, row : 2, col : 8 } ]);
      const result = aether.run();
      return expect(result).toEqual(45);
    });

    xit("Missing self: x() row 0", function() {
      const code = "x()";
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(1);
      expect(aether.problems.errors[0].message).toEqual("Missing `self` keyword; should be `self.x`.");
      return expect(aether.problems.errors[0].range).toEqual([ { ofs: 0, row: 0, col: 0 }, { ofs: 3, row: 0, col: 3 } ]);
    });

    xit("Missing self: x() row 1", function() {
      const code = `\
y = 5
x()\
`;
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(1);
      expect(aether.problems.errors[0].message).toEqual("Missing `self` keyword; should be `self.x`.");
      return expect(aether.problems.errors[0].range).toEqual([ { ofs: 6, row: 1, col: 0 }, { ofs: 9, row: 1, col: 3 } ]);
    });

    xit("Missing self: x() row 3", function() {
      const code = `\
y = 5
s = 'some other stuff'
if y is 5:
  x()\
`;
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(1);
      expect(aether.problems.errors[0].message).toEqual("Missing `self` keyword; should be `self.x`.");
      return expect(aether.problems.errors[0].range).toEqual([ { ofs: 42, row: 3, col: 2 }, { ofs: 45, row: 3, col: 5 } ]);
    });

    it("self.getItems missing parentheses", function() {
      const code = `\
self.getItems\
`;
      aether = new Aether({language: 'python', problemContext: {thisMethods: ['getItems']}});
      aether.transpile(code);
      aether.run();
      expect(aether.problems.errors.length).toEqual(1);
      expect(aether.problems.errors[0].message).toEqual('self.getItems has no effect. It needs parentheses: self.getItems()');
      return expect(aether.problems.errors[0].range).toEqual([ { ofs : 0, row : 0, col : 0 }, { ofs : 13, row : 0, col : 13 } ]);
    });

    it("self.getItems missing parentheses row 1", function() {
      const code = `\
x = 5
self.getItems\
`;
      aether = new Aether({language: 'python', problemContext: {thisMethods: ['getItems']}});
      aether.transpile(code);
      aether.run();
      expect(aether.problems.errors.length).toEqual(1);
      expect(aether.problems.errors[0].message).toEqual('self.getItems has no effect. It needs parentheses: self.getItems()');
      return expect(aether.problems.errors[0].range).toEqual([ { ofs : 6, row : 1, col : 0 }, { ofs : 19, row : 1, col : 13 } ]);
    });

    it("Incomplete string", function() {
      const code = `\
s = 'hi
return s\
`;
      aether.transpile(code);
      expect(aether.problems.errors.length).toEqual(1);
      expect(/Unterminated string constant/.test(aether.problems.errors[0].message)).toBe(true);
      expect(aether.problems.errors[0].range).toEqual([ { ofs : 4, row : 0, col : 4 }, { ofs : 7, row : 0, col : 7 } ]);
      const result = aether.run();
      return expect(result).toEqual('hi');
    });

    return it("Runtime ReferenceError", function() {
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

  xdescribe("Simple loop", function() {
    it("loop:", function() {
      const code = `\
total = 0
loop:
  total += 1
  if total is 10: break;
return total\
`;
      const aether = new Aether({language: "python", simpleLoops: true});
      aether.transpile(code);
      return expect(aether.run()).toEqual(10);
    });

    it("loop : (whitespace)", function() {
      const code = `\
total = 0
loop  :
  total += 1
  if total is 10: break;
return total\
`;
      const aether = new Aether({language: "python", simpleLoops: true});
      aether.transpile(code);
      return expect(aether.run()).toEqual(10);
    });

    it("loop : (no :)", function() {
      const code = `\
total = 0
loop
  total += 1
  if total is 10: break;
return total\
`;
      const aether = new Aether({language: "python", simpleLoops: true});
      aether.transpile(code);
      expect(aether.problems.warnings.length).toEqual(1);
      expect(aether.problems.warnings[0].type).toEqual('transpile');
      expect(aether.problems.warnings[0].message).toEqual("You are missing a ':' after 'loop'. Try `loop:`");
      return expect(aether.run()).toEqual(10);
    });


    xit("one line", function() {
      // Blocked by https://github.com/differentmatt/filbert/issues/41
      const code = `\
total = 0
loop: total += 12; break;
return total\
`;
      const aether = new Aether({language: "python", simpleLoops: true});
      aether.transpile(code);
      return expect(aether.run()).toEqual(12);
    });

    xit("loop  :", function() {
      // Blocked by https://github.com/codecombat/aether/issues/108
      const code = `\
total = 0
loop  :
  total += 23;
  break;
return total\
`;
      const aether = new Aether({language: "python", simpleLoops: true});
      aether.transpile(code);
      return expect(aether.run()).toEqual(23);
    });

    it("Conditional yielding", function() {
      const aether = new Aether({language: "python", yieldConditionally: true, simpleLoops: true});
      const dude = {
        killCount: 0,
        slay() {
          this.killCount += 1;
          return aether._shouldYield = true;
        },
        getKillCount() { return this.killCount; }
      };
      const code = `\
while True:
  self.slay();
  break;
loop:
  self.slay();
  if self.getKillCount() >= 5:
    break;
while True:
  self.slay();
  break;\
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

    it("Conditional yielding empty loop", function() {
      const aether = new Aether({language: "python", yieldConditionally: true, simpleLoops: true});
      const dude = {
        killCount: 0,
        slay() {
          this.killCount += 1;
          return aether._shouldYield = true;
        },
        getKillCount() { return this.killCount; }
      };
      const code = `\
x = 0
loop:
  x += 1
  if x >= 3:
    break\
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
      const aether = new Aether({language: "python", yieldConditionally: true, simpleLoops: true});
      const dude = {
        killCount: 0,
        slay() {
          this.killCount += 1;
          return aether._shouldYield = true;
        },
        getKillCount() { return this.killCount; }
      };
      const code = `\
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
  break\
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
      const aether = new Aether({language: "python", yieldConditionally: true, simpleLoops: true});
      const dude = {
        killCount: 0,
        slay() {
          this.killCount += 1;
          return aether._shouldYield = true;
        },
        getKillCount() { return this.killCount; }
      };
      const code = `\
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
    break\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);

      // NOTE: auto yield loops break before invisible automatic yield

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

    return it("Empty loop", function() {
      const code = `\
loop:
x = 5\
`;
      const aether = new Aether({language: "python", simpleLoops: true});
      aether.transpile(code);
      expect(aether.problems.warnings.length).toEqual(1);
      expect(aether.problems.warnings[0].type).toEqual('transpile');
      return expect(aether.problems.warnings[0].message).toEqual("Empty loop. Put 4 spaces in front of statements inside loops.");
    });
  });

    // TODO: simple loop in a function
    // TODO: blocked by https://github.com/codecombat/aether/issues/48

  return xdescribe("whileTrueAutoYield", function() {
    it("while True: no yieldConditionally", function() {
      const code = `\
total = 0
while True:
  total += 1
  if total is 10: break;
return total\
`;
      const aether = new Aether({language: "python", whileTrueAutoYield: true});
      aether.transpile(code);
      return expect(aether.run()).toEqual(10);
    });

    it("Conditional yielding and simpleLoops", function() {
      const aether = new Aether({language: "python", yieldConditionally: true, whileTrueAutoYield: true, simpleLoops: true});
      const dude = {};
      const code = `\
x = 0
while True:
  x += 1
  if x >= 3:
    break
x = 0
loop:
  x += 1
  if x >= 3:
    break\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(false);
      expect(gen.next().done).toEqual(false);
      return expect(gen.next().done).toEqual(true);
    });

    it("Conditional yielding empty loop", function() {
      const aether = new Aether({language: "python", yieldConditionally: true, whileTrueAutoYield: true});
      const dude = {};
      const code = `\
x = 0
while True:
  x += 1
  if x >= 3:
    break\
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
      const aether = new Aether({language: "python", yieldConditionally: true, whileTrueAutoYield: true});
      const dude = {
        killCount: 0,
        slay() {
          this.killCount += 1;
          return aether._shouldYield = true;
        },
        getKillCount() { return this.killCount; }
      };
      const code = `\
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
  break\
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
      const aether = new Aether({language: "python", yieldConditionally: true, whileTrueAutoYield: true});
      const dude = {
        killCount: 0,
        slay() {
          this.killCount += 1;
          return aether._shouldYield = true;
        },
        getKillCount() { return this.killCount; }
      };
      const code = `\
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
    break\
`;
      aether.transpile(code);
      const f = aether.createFunction();
      const gen = f.apply(dude);

      // NOTE: auto yield loops break before invisible automatic yield

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

    return it("Empty loop", function() {
      const code = `\
while True:
x = 5\
`;
      const aether = new Aether({language: "python", whileTrueAutoYield: true});
      aether.transpile(code);
      console.log(JSON.stringify(aether.problems));
      expect(aether.problems.warnings.length).toEqual(1);
      expect(aether.problems.warnings[0].type).toEqual('transpile');
      return expect(aether.problems.warnings[0].message).toEqual("Empty loop. Put 4 spaces in front of statements inside loops.");
    });
  });
});
