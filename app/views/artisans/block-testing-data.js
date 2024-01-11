const propertyEntryGroups = {
  Deflector: {
    props: [
      { args: [{ type: 'object', name: 'target' }], type: 'function', name: 'bash', owner: 'this', ownerName: 'hero' },
      { owner: 'this', type: 'function', name: 'shield', ownerName: 'hero' }
    ]
  },
  'Sword of the Temple Guard': {
    props: [
      { returns: { type: 'number' }, args: [{ default: '', type: 'object', name: 'target' }], type: 'function', name: 'attack', owner: 'this', ownerName: 'hero' },
      { type: 'number', name: 'attackDamage', owner: 'this', ownerName: 'hero' },
      { type: 'function', name: 'powerUp', owner: 'this', ownerName: 'hero' }]
  },
  'Twilight Glasses': {
    props: [
      { args: [{ default: '', type: 'object', name: 'target' }], type: 'function', name: 'distanceTo', owner: 'this', ownerName: 'hero' },
      {
        returns: { type: 'array' },
        args: [
          { type: 'string', name: 'type' },
          { type: 'array', name: 'units' }
        ],
        type: 'function',
        name: 'findByType',
        owner: 'this',
        ownerName: 'hero'
      },
      { returns: { type: 'array' }, name: 'findEnemies', type: 'function', owner: 'this', ownerName: 'hero' },
      { returns: { type: 'array' }, name: 'findFriends', type: 'function', owner: 'this', ownerName: 'hero' },
      { returns: { type: 'array' }, name: 'findItems', type: 'function', owner: 'this', ownerName: 'hero' },
      { returns: { type: 'object' }, name: 'findNearest', type: 'function', args: [{ name: 'units', type: 'array' }], owner: 'this', ownerName: 'hero' },
      { returns: { type: 'object' }, name: 'findNearestEnemy', type: 'function', owner: 'this', ownerName: 'hero' },
      { returns: { type: 'object' }, name: 'findNearestItem', type: 'function', owner: 'this', ownerName: 'hero' },
      { returns: { type: 'array' }, name: 'findEnemyMissiles', type: 'function', owner: 'this', ownerName: 'hero' },
      { returns: { type: 'array' }, name: 'findFriendlyMissiles', type: 'function', owner: 'this', ownerName: 'hero' },
      { returns: { type: 'array' }, type: 'function', name: 'findHazards', owner: 'this', ownerName: 'hero' },
      {
        name: 'isPathClear',
        type: 'function',
        returns: { type: 'boolean' },
        args: [
          { name: 'start', type: 'object' },
          { name: 'end', type: 'object' }
        ],
        owner: 'this',
        ownerName: 'hero'
      }]
  },
  'Sapphire Sense Stone': {
    props: [
      { returns: { type: 'boolean' }, owner: 'this', args: [{ type: 'string', name: 'effect' }], type: 'function', name: 'hasEffect', ownerName: 'hero' },
      { name: 'health', type: 'number', owner: 'this', ownerName: 'hero' },
      { name: 'maxHealth', type: 'number', owner: 'this', ownerName: 'hero' },
      { type: 'object', name: 'pos', owner: 'this', ownerName: 'hero' },
      { type: 'number', name: 'gold', owner: 'this', ownerName: 'hero' },
      { name: 'target', type: 'object', owner: 'this', ownerName: 'hero' },
      { name: 'targetPos', type: 'object', owner: 'this', ownerName: 'hero' },
      { type: 'object', name: 'velocity', owner: 'this', ownerName: 'hero' }]
  },
  "Emperor's Gloves": {
    props: [
      {
        returns: { type: 'boolean' },
        args: [
          { type: 'string', name: 'spell' },
          { type: 'object', name: 'target' }
        ],
        type: 'function',
        name: 'canCast',
        owner: 'this',
        ownerName: 'hero'
      },
      {
        args: [
          { type: 'string', name: 'spell' },
          { type: 'object', name: 'target' }
        ],
        type: 'function',
        name: 'cast',
        owner: 'this',
        ownerName: 'hero'
      },
      { args: [{ default: '', type: 'object', name: 'target' }], type: 'function', name: 'castChainLightning', owner: 'this', ownerName: 'hero' },
      { type: 'object', name: 'spells', owner: 'this', ownerName: 'hero' }]
  },
  'Gilt Wristwatch': {
    props: [
      { name: 'findCooldown', type: 'function', args: [{ name: 'action', type: 'string' }], returns: { type: 'number' }, owner: 'this', ownerName: 'hero' },
      { name: 'isReady', type: 'function', returns: { type: 'boolean' }, args: [{ name: 'action', type: 'string' }], owner: 'this', ownerName: 'hero' },
      { type: 'Number', name: 'time', owner: 'this', ownerName: 'hero' },
      { name: 'wait', type: 'function', args: [{ name: 'duration', type: 'number', default: '' }], owner: 'this', ownerName: 'hero' }]
  },
  'Caltrop Belt': {
    props: [
      { owner: 'this', type: 'array', name: 'buildTypes', ownerName: 'hero' },
      {
        owner: 'this',
        args: [
          { default: '', type: 'string', name: 'buildType' },
          { type: 'number', name: 'x' },
          { type: 'number', name: 'y' }
        ],
        type: 'function',
        name: 'buildXY',
        ownerName: 'hero'
      }]
  },
  'Simple Boots': {
    props: [
      { type: 'function', name: 'moveDown', args: [{ name: 'steps', type: 'number', default: 1 }], owner: 'this', ownerName: 'hero' },
      { type: 'function', name: 'moveLeft', args: [{ name: 'steps', type: 'number', default: 1 }], owner: 'this', ownerName: 'hero' },
      { type: 'function', name: 'moveRight', args: [{ name: 'steps', type: 'number', default: 1 }], owner: 'this', ownerName: 'hero' },
      { type: 'function', name: 'moveUp', args: [{ name: 'steps', type: 'number', default: 1 }], owner: 'this', ownerName: 'hero' },
      { type: 'function', name: 'moveTo', args: [{ name: 'point', type: 'number', default: 1 }], owner: 'this', ownerName: 'hero' }]
  },
  'Ring of Earth': {
    props: [
      { name: 'castEarthskin', type: 'function', args: [{ name: 'target', type: 'object', default: '' }], owner: 'this', ownerName: 'hero' }]
  },
  'Boss Star V': {
    props: [
      { owner: 'this', type: 'array', name: 'built', ownerName: 'hero' },
      {
        name: 'command',
        type: 'function',
        args: [
          { name: 'minion', type: 'object' },
          { name: 'method', type: 'string' },
          { name: 'arg1', type: 'object', optional: true },
          { name: 'arg2', type: 'object', optional: true }
        ],
        owner: 'this',
        ownerName: 'hero'
      },
      { name: 'commandableMethods', type: 'array', owner: 'this', ownerName: 'hero' },
      { name: 'commandableTypes', type: 'array', owner: 'this', ownerName: 'hero' },
      { args: [{ default: '', type: 'string', name: 'buildType' }], returns: { type: 'number' }, type: 'function', name: 'costOf', owner: 'this', ownerName: 'hero' },
      { returns: { type: 'object' }, owner: 'this', args: [{ default: '', type: 'string', name: 'summonType' }], type: 'function', name: 'summon', ownerName: 'hero' }]
  },
  "Master's Flags": {
    props: [
      { returns: { type: 'object' }, name: 'addFlag', type: 'function', owner: 'this', ownerName: 'hero' },
      { args: [{ type: 'string', name: 'color' }], returns: { type: 'object' }, type: 'function', name: 'findFlag', owner: 'this', ownerName: 'hero' },
      { returns: { type: 'array' }, type: 'function', name: 'findFlags', owner: 'this', ownerName: 'hero' },
      { args: [{ type: 'flag', name: 'flag' }], type: 'function', name: 'pickUpFlag', owner: 'this', ownerName: 'hero' },
      { args: [{ type: 'flag', name: 'flag' }], type: 'function', name: 'removeFlag', owner: 'this', ownerName: 'hero' }]
  },
  Pugicorn: {
    props: [
      { name: 'pet', type: 'object', owner: 'this', ownerName: 'hero' },
      { owner: 'snippets', args: [{ type: 'object', name: 'enemy' }], type: 'snippet', name: 'pet.charm(enemy)' },
      { args: [{ type: 'object', name: 'item' }], owner: 'snippets', type: 'snippet', name: 'pet.fetch(item)' },
      { owner: 'snippets', returns: { type: 'object' }, args: [{ type: 'string', name: 'type' }], type: 'snippet', name: 'pet.findNearestByType(type)' },
      { owner: 'snippets', args: [{ type: 'string', name: 'ability' }], returns: { type: 'boolean' }, type: 'snippet', name: 'pet.isReady(ability)' },
      {
        owner: 'snippets',
        name: 'pet.moveXY(x, y)',
        type: 'snippet',
        args: [
          { name: 'x', type: 'number', default: '' },
          { name: 'y', type: 'number', default: '' }
        ]
      },
      {
        owner: 'snippets',
        args: [
          { type: 'string', name: 'eventType' },
          { type: 'function', name: 'handler' }
        ],
        type: 'snippet',
        name: 'pet.on(eventType, handler)'
      },
      { owner: 'snippets', name: 'pet.say(message)', type: 'snippet', args: [{ name: 'message', type: 'string', default: '' }] },
      { owner: 'snippets', type: 'snippet', name: 'pet.trick()' }]
  },
  'Programmaticon V': {
    props: [
      { name: 'debug', type: 'function', owner: 'this', ownerName: 'hero' },
      { owner: 'snippets', type: 'snippet', name: 'arrays' },
      { owner: 'snippets', codeLanguages: ['javascript', 'python', 'coffeescript', 'lua', 'io'], type: 'snippet', name: 'break' },
      { owner: 'snippets', codeLanguages: ['javascript', 'python', 'coffeescript', 'lua', 'io'], type: 'snippet', name: 'continue' },
      { owner: 'snippets', type: 'snippet', name: 'else' },
      { owner: 'snippets', type: 'snippet', name: 'for-in-loop' },
      { owner: 'snippets', type: 'snippet', name: 'for-loop' },
      { owner: 'snippets', type: 'snippet', name: 'functions' },
      { owner: 'snippets', type: 'snippet', name: 'if/else' },
      { owner: 'snippets', codeLanguages: ['python', 'coffeescript'], type: 'snippet', name: 'list comprehensions' },
      { owner: 'snippets', type: 'snippet', name: 'objects' },
      { owner: 'snippets', type: 'snippet', name: 'while-loop' },
      { owner: 'snippets', type: 'snippet', name: 'while-true loop' }]
  }
}

const tests = []

tests.push({
  name: 'Simple',
  code: `
hero.moveRight()
hero.moveDown()
hero.moveRight()`,
  codeLanguage: 'javascript'
})

tests.push({
  name: 'Numeric arguments',
  code: `
hero.moveRight()
hero.moveDown(1)
hero.moveUp(2)
hero.moveRight()`,
  codeLanguage: 'javascript'
})

tests.push({
  name: 'String arguments',
  code: `
hero.say("Hello")
hero.say('World')`,
  codeLanguage: 'javascript'
})

tests.push({
  name: 'Variable',
  code: `
var greeting = "Hello"
hero.say(greeting)
hero.say("World")`,
  codeLanguage: 'javascript'
})

tests.push({
  name: 'var / let / const',
  code: `
var g1 = "Hello"
let g2 = "World"
const g3 = " "
g2 = g1 + g2 + g3
hero.say(g2)
`,
  codeLanguage: 'javascript'
})

tests.push({
  name: 'Multiple blocks of blocks with line breaks',
  code: `
hero.say("Hi")
hero.say("Mom")

hero.say("I'm")
hero.say("so")
hero.say("hungry")


hero.say("Pizza?")
`,
  codeLanguage: 'javascript'
})

tests.push({
  name: 'Comment lines',
  code: `
// Defend against "Brak" and "Treg"!
// You must attack small ogres twice.

hero.moveRight();
hero.attack("Brak");
hero.attack("Brak");
hero.moveRight();
hero.attack("Treg");
hero.attack("Treg");`,
  codeLanguage: 'javascript'
})

tests.push({
  name: 'Legal thing to do',
  code: `
hero.moveLeft(hero.attackDamage)
`,
  codeLanguage: 'javascript'
})

tests.push({
  name: 'While loops',
  code: `
while (true) {
    hero.moveRight()
    hero.moveDown()

    hero.moveLeft()
    hero.moveUp()
}
`,
  codeLanguage: 'javascript'
})

tests.push({
  name: 'String concatenation',
  code: `
    hero.say("I'm glad my health is " + hero.health + ' and not potato.')
`,
  codeLanguage: 'javascript'
})

tests.push({
  name: 'Break/continue',
  code: `
while (true) {
    hero.moveRight()

    if (hero.health <= 25) {
        break
    }

    if (hero.health < hero.maxHealth * 2) {
        continue
    }

    hero.moveLeft()
}

while (hero.health !== 'potato') {
    hero.say("I'm glad my health is " + hero.health + ' and not potato.')
}
`,
  codeLanguage: 'javascript'
})

tests.push({
  name: 'If/else',
  code: `
if (hero.health < 25) {
    hero.say("I'm dying!")
} else {
    hero.say("I'm fine!")
}
`,
  codeLanguage: 'javascript'
})

tests.push({
  name: 'If/else if/else',
  code: `
if (hero.health < 25) {
    hero.say("I'm dying!")
} else if (hero.health < 50) {
    hero.say("I'm hurt!")
} else {
    hero.say("I'm fine!")
}
`,
  codeLanguage: 'javascript'
})

tests.push({
  name: 'Python if/else',
  code: `
if hero.health < 25:
    hero.say("I'm dying!")
else:
    hero.say("I'm fine!")
`,
  codeLanguage: 'python'
})

tests.push({
  name: 'Python if/elif/else',
  code: `
if hero.health < 25:
    hero.say("I'm dying!")
elif hero.health < 50:
    hero.say("I'm hurt!")
else:
    hero.say("I'm fine!")
`,
  codeLanguage: 'python'
})

tests.push({
  name: 'Functions',
  code: `
function foobar() {
    hero.say("foo")
    hero.say("bar")
}

foobar()

function baz(x) {
    return x * x
}

hero.say(baz(baz(baz(2))))
`,
  codeLanguage: 'javascript'
})

tests.push({
  name: 'Functions - Arrow',
  code: `
const baz = (x) => x * x

hero.say(baz(baz(baz(2))))
`,
  codeLanguage: 'javascript'
})

tests.push({
  name: 'Arrays',
  code: `
const quux = 'I think, therefore I am'
const quuux = ['a', 2, ['c', 'd'], quux]

hero.say(quuux[quuux.length - 1][3])

const primes = [
    2,
    3,
    4,
    5,
    7
]

delete primes[2]
`,
  codeLanguage: 'javascript'
})

tests.push({
  name: 'Arrays - Push',
  code: `
const list = ['a', 'b']
list.push('c')
`,
  codeLanguage: 'javascript'
})

tests.push({
  name: 'Objects',
  code: `
const foo = {
    bar: 2,
    baz: 'quux'
}

hero.say(foo.bar)
hero.say(foo.baz)

foo['quux'] = foo.bar
foo.quux = foo.baz
foo.foo = foo
foo['foo'].foo = foo

for (const key in foo) {
    hero.say(key + ' is ' + foo[key])
}

for (const val of foo) {
    hero.say(val)
}
`,
  codeLanguage: 'javascript'
})

tests.push({
  name: 'For loops',
  code: `
for (let i = 0; i < 10; i++) {
    hero.say(i)
}
`,
  codeLanguage: 'javascript'
})

tests.push({
  name: 'Ternary Operator',
  code: `
const foo = true ? 'bar' : 'baz'
hero.say(foo)
`,
  codeLanguage: 'javascript'
})

tests.push({
  name: 'Python, newlines',
  code: `
# Defeat the ogres.
# Remember that they each take two hits.

hero.attack("Rig")
hero.attack("Rig")

hero.attack("Gurt")
hero.attack("Gurt")

hero.attack("Ack")`,
  codeLanguage: 'python'
})

tests.push({
  name: 'Python, Numeric arguments',
  code: `
hero.moveRight()
hero.moveDown(1)
hero.moveUp(2)
hero.moveRight()`,
  codeLanguage: 'python'
})

tests.push({
  name: 'Python, String arguments',
  code: `
hero.say("Hello")
hero.say('World')`,
  codeLanguage: 'python'
})

tests.push({
  name: 'Python, Variable',
  code: `
greeting = "Hello"
hero.say(greeting)
hero.say("World")`,
  codeLanguage: 'python'
})

tests.push({
  name: 'Python, Comment lines',
  code: `
# Defend against "Brak" and "Treg"!
# You must attack small ogres twice.

hero.moveRight()
hero.attack("Brak")
hero.attack("Brak")
hero.moveRight()
hero.attack("Treg")
hero.attack("Treg")`,
  codeLanguage: 'python'
})

tests.push({
  name: 'Python, nested comments',
  code: `
# I'm on top of the world!
while True:
    # I must go deeper.

    while True:
        # I drink your milkshake.
  `,
  codeLanguage: 'python'
})

tests.push({
  name: 'Python, Legal thing to do',
  code: `
hero.moveLeft(hero.attackDamage)
`,
  codeLanguage: 'python'
})

tests.push({
  name: 'Python, While loops',
  code: `
while True:
    hero.moveRight()
    hero.moveDown()

    hero.moveLeft()
    hero.moveUp()
`,
  codeLanguage: 'python'
})

tests.push({
  name: 'Python, String concatenation',
  code: `
    hero.say("I'm glad my health is " + hero.health + ' and not potato.')
`,
  codeLanguage: 'python'
})

tests.push({
  name: 'Python, Break/continue',
  code: `
while True:
    hero.moveRight()

    if hero.health <= 25:
        break

    if hero.health < hero.maxHealth * 2:
        continue

    hero.moveLeft()

while hero.health != 'potato':
    hero.say("I'm glad my health is " + hero.health + ' and not potato.')
`,
  codeLanguage: 'python'
})

tests.push({
  name: 'Python, Functions',
  code: `
def foobar():
    hero.say("foo")
    hero.say("bar")

foobar()

def baz(x):
    return x * x

hero.say(baz(baz(baz(2))))
`,
  codeLanguage: 'python'
})

tests.push({
  name: 'Python, Arrays',
  code: `
quux = 'I think, therefore I am'
quuux = ['a', 2, ['c', 'd'], quux]

hero.say(quuux[quuux.length - 1][3])

primes = [
    2,
    3,
    4,
    5,
    7
]

del primes[2]
`,
  codeLanguage: 'python'
})

tests.push({
  name: 'Python, Objects',
  code: `
foo = {
    'bar': 2,
    'baz': 'quux'
}

hero.say(foo['bar'])
hero.say(foo['baz'])

foo['quux'] = foo['bar']
foo['quux'] = foo['baz']
foo['foo'] = foo
foo['foo']['foo'] = foo

for key in foo:
    hero.say(key + ' is ' + foo[key])

for val in foo:
    hero.say(val)
`,
  codeLanguage: 'python'
})

tests.push({
  name: 'Python, Ternary Operator',
  code: `
foo = 'bar' if True else 'baz'
hero.say(foo)
`,
  codeLanguage: 'python'
})

tests.push({
  name: 'Python, Functions - Arrow',
  code: `
baz = lambda x: x * x

hero.say(baz(baz(baz(2))))
`,
  codeLanguage: 'python'
})

tests.push({
  name: 'Python, Arrays - Push',
  code: `
list = ['a', 'b']
list.append('c')
`,
  codeLanguage: 'python'
})

tests.push({
  name: 'Python, For loops',
  code: `
for i in range(0, 10):
    hero.say(i)

for i in range(0, 10, 2):
    hero.say(i)

for i in range(10, 0, -1):
    hero.say(i)

for i in range(10, 0, -2):
    hero.say(i)
`,
  codeLanguage: 'python'
})

tests.push({
  name: 'Python, For loops - Array',
  code: `
for i in [1, 2, 3]:
    hero.say(i)
`,
  codeLanguage: 'python'
})

tests.push({
  name: 'Python, For loops - Array - String',
  code: `
for i in 'abc':
    hero.say(i)
`,
  codeLanguage: 'python'
})

tests.push({
  name: 'Python, For loops - Array - String - Break',
  code: `
for i in 'abc':
    hero.say(i)
    break

for i in 'abc':
    hero.say(i)
    continue
`,
  codeLanguage: 'python'
})

tests.push({
  name: 'D',
  code: `
// Grab all the gems using your movement commands.

hero.moveRight();
d
`,
  codeLanguage: 'javascript'
})

tests.push({
  name: 'Raw',
  code: `
const foo = {
    bar: 2,
    baz: 'quux'
}

var x = 10
hero.attack(x)
`,
  codeLanguage: 'javascript'
})

tests.push({
  name: 'While loop with comment',
  code: `
while (true) {
    // Add some code to do ANYTHING
    ` + `
}
`,
  codeLanguage: 'javascript'
})

tests.push({
  name: 'Intro comment section entry points',
  code: `
// This has some comments at the top
// Those comments should not produce an entry point

var foo = "bar"
// Now, young Jedi, use the Code Here


while (true) {
    // Add some code to do ANYTHING
    ` + `
}
`,
  codeLanguage: 'javascript'
})

module.exports = {
  propertyEntryGroups,
  initialTestCases: tests
}
