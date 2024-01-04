let BlockTestingView
require('app/styles/artisans/block-testing-view.sass')
const RootView = require('views/core/RootView')
const template = require('templates/artisans/block-testing-view')
const loadAetherLanguage = require('lib/loadAetherLanguage')
const blocklyUtils = require('core/blocklyUtils')
const Blockly = require('blockly')
const { codeToBlocks, prepareBlockIntelligence } = require('lib/code-to-blocks')
const aceLib = require('lib/aceContainer')
const aceUtils = require('core/aceUtils')
const storage = require('core/storage')
const utils = require('core/utils')

const testCases = []
let propertyEntryGroups
let prepData = null

const PERSIST_BLOCK_STATE = false

module.exports = (BlockTestingView = (function () {
  BlockTestingView = class BlockTestingView extends RootView {
    static initClass () {
      this.prototype.template = template
      this.prototype.id = 'block-testing-view'
      this.prototype.testCases = testCases
    }

    constructor (options, levelSlug) {
      super(options)
      blocklyUtils.registerBlocklyTheme()
      blocklyUtils.initializeBlocklyTooltips()
      this.focusTest = utils.getQueryVariable('test')
      this.focusLanguage = utils.getQueryVariable('codeLanguage')
      // Ensure Esper is fully loaded, including babylon (used in Python)
      loadAetherLanguage('python').then((aetherLang) => {
        loadAetherLanguage('javascript').then((aetherLang) => {
          this.addTestCases()
        })
      })
    }

    addTestCases () {
      this.render()
      for (let i = 0; i < testCases.length; ++i) {
        const testCase = testCases[i]
        const testContainer = $(this.$el.find('.test-case')[i])
        if (this.focusTest && this.focusTest !== testCase.name) {
          testContainer.hide()
          continue
        }
        if (this.focusLanguage && this.focusLanguage !== testCase.codeLanguage) {
          testContainer.hide()
          continue
        }
        const { inputAce, outputAce } = this.addAce({ testCase, testContainer })
        this.addBlockly({ testCase, testContainer, inputAce, outputAce })
      }
    }

    addAce ({ testCase, testContainer }) {
      const codeLanguage = testCase.codeLanguage
      const aces = { input: null, output: null }
      for (const key in aces) {
        const ace = aceLib.edit(testContainer.find(`.ace-${key}`)[0])
        this.configureAce(ace, testCase.codeLanguage)
        if (key === 'input') {
          ace.setValue(testCase.code.trim())
          ace.clearSelection()
        } else {
          ace.setReadOnly(true)
        }
        aces[key] = ace
      }
      return { inputAce: aces.input, outputAce: aces.output }
    }

    addBlockly ({ testCase, testContainer, inputAce, outputAce }) {
      // Initialize Blockly
      const toolbox = blocklyUtils.createBlocklyToolbox({ propertyEntryGroups, codeLanguage: testCase.codeLanguage })
      // codeToBlocks prepareBlockIntelligence function needs the JavaScript version of the toolbox
      const toolboxJS = testCase.codeLanguage === 'javascript' ? toolbox : blocklyUtils.createBlocklyToolbox({ propertyEntryGroups, codeLanguage: 'javascript' })
      const blocklyDiv = testContainer.find('.blockly-container')[0]
      const blocklyOptions = blocklyUtils.createBlocklyOptions({ toolbox })
      const blocklyWorkspace = Blockly.inject(blocklyDiv, blocklyOptions)
      const lastBlocklyState = PERSIST_BLOCK_STATE ? storage.load(`lastBlocklyState_${testCase.name}`) : null
      if (lastBlocklyState) {
        blocklyUtils.loadBlocklyState(lastBlocklyState, blocklyWorkspace)
      }
      const { blocklyState, blocklySource } = blocklyUtils.getBlocklySource(blocklyWorkspace, testCase.codeLanguage)
      console.log('Initialized Blockly for test case', testCase.name, '\nBlockly toolbox:', toolbox, '\nBlockly options:', blocklyOptions, '\nBlockly workspace:', blocklyWorkspace, '\Blockly state', blocklyState)

      const debugBlocklyDiv = testContainer.find('.blockly-container-debug')[0]
      const debugBlocklyWorkspace = Blockly.inject(debugBlocklyDiv, blocklyOptions)
      const debugDiv = testContainer.find('.debug-scratchpad')[0]
      const errorDiv = testContainer.find('.error-scratchpad')[0]

      // If this is the first time, get some prep data for initial codeToBlocks setup and debugging
      let prepDataError
      if (!prepData) {
        try {
          prepData = prepareBlockIntelligence({ toolbox: toolboxJS, blocklyState, workspace: debugBlocklyWorkspace })
        } catch (err) {
          console.error(err)
          prepData = {}
          testContainer.find('debug-error').text(err.message).removeClass('hide')
          prepDataError = err
        }
      }

      // Hook up input ace -> Blockly change listener
      const onAceChange = () => {
        const newBlocklyState = this.runCodeToBlocks({ testCase, code: inputAce.getValue(), codeLanguage: testCase.codeLanguage, toolbox, blocklyState, debugDiv, errorDiv, debugBlocklyWorkspace, prepData, prepDataError })
        if (newBlocklyState) {
          blocklyUtils.loadBlocklyState(newBlocklyState, blocklyWorkspace)
        }
      }
      inputAce.getSession().getDocument().on('change', onAceChange)
      onAceChange()

      // Hook up Blockly -> output ace change listener
      blocklyWorkspace.addChangeListener((event) => {
        const { blocklyState, blocklySource } = blocklyUtils.getBlocklySource(blocklyWorkspace, testCase.codeLanguage)
        if (PERSIST_BLOCK_STATE) {
          storage.save(`lastBlocklyState_${testCase.name}`, blocklyState)
        }
        console.log('New blockly state for', testCase.name, 'is', blocklyState)
        outputAce.setValue(blocklySource)
        outputAce.clearSelection()
      })
    }

    runCodeToBlocks ({ testCase, code, codeLanguage, toolbox, blocklyState, debugDiv, errorDiv, debugBlocklyWorkspace, prepData, prepDataError }) {
      try {
        const newBlocklyState = codeToBlocks({ code, codeLanguage, toolbox, blocklyState, debugDiv, debugBlocklyWorkspace, prepData })
        if (!prepDataError) {
          $(errorDiv).text('').addClass('hide')
        }
        if (newBlocklyState) {
          console.log('codeToBlocks produced new blockly state for', testCase.name, 'as', newBlocklyState)
          return newBlocklyState
        }
      } catch (err) {
        console.error('codeToBlocks errored out:', err)
        const errMessage = (prepDataError ? prepDataError.message + '\n' : '') + err.message
        $(errorDiv).text(errMessage).removeClass('hide')
        return null
      }
    }

    afterRender () {
      super.afterRender()
    }

    configureAce (ace, codeLanguage) {
      const aceSession = ace.getSession()
      const aceDoc = aceSession.getDocument()
      aceSession.setUseWorker(false)
      aceSession.setMode(aceUtils.aceEditModes[codeLanguage])
      aceSession.setWrapLimitRange(null)
      aceSession.setUseWrapMode(true)
      aceSession.setNewLineMode('unix')
      aceSession.setUseSoftTabs(true)
      ace.setTheme('ace/theme/textmate')
      ace.setDisplayIndentGuides(false)
      ace.setShowPrintMargin(false)
      ace.setShowInvisibles(false)
      ace.setBehavioursEnabled(false)
      ace.setAnimatedScroll(true)
      ace.setShowFoldWidgets(false)
      ace.$blockScrolling = Infinity
    }
  }

  BlockTestingView.initClass()
  return BlockTestingView
})())

testCases.push({
  name: 'Simple',
  code: `
hero.moveRight()
hero.moveDown()
hero.moveRight()`,
  codeLanguage: 'javascript'
})

testCases.push({
  name: 'Numeric arguments',
  code: `
hero.moveRight()
hero.moveDown(1)
hero.moveUp(2)
hero.moveRight()`,
  codeLanguage: 'javascript'
})

testCases.push({
  name: 'String arguments',
  code: `
hero.say("Hello")
hero.say('World')`,
  codeLanguage: 'javascript'
})

testCases.push({
  name: 'Variable',
  code: `
var greeting = "Hello"
hero.say(greeting)
hero.say("World")`,
  codeLanguage: 'javascript'
})

testCases.push({
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

testCases.push({
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

testCases.push({
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

testCases.push({
  name: 'Legal thing to do',
  code: `
hero.moveLeft(hero.attackDamage)
`,
  codeLanguage: 'javascript'
})

testCases.push({
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

testCases.push({
  name: 'String concatenation',
  code: `
    hero.say("I'm glad my health is " + hero.health + ' and not potato.')
`,
  codeLanguage: 'javascript'
})


testCases.push({
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

testCases.push({
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

testCases.push({
  name: 'Functions - Arrow',
  code: `
const baz = (x) => x * x

hero.say(baz(baz(baz(2))))
`,
  codeLanguage: 'javascript'
})

testCases.push({
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

testCases.push({
  name: 'Arrays - Push',
  code: `
const list = ['a', 'b']
list.push(c)
`,
  codeLanguage: 'javascript'
})

testCases.push({
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

testCases.push({
  name: 'For loops',
  code: `
for (let i = 0; i < 10; i++) {
    hero.say(i)
}
`,
  codeLanguage: 'javascript'
})

testCases.push({
  name: 'Ternary Operator',
  code: `
const foo = true ? 'bar' : 'baz'
hero.say(foo)
`,
  codeLanguage: 'javascript'
})

testCases.push({
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

testCases.push({
  name: 'Python, Numeric arguments',
  code: `
hero.moveRight()
hero.moveDown(1)
hero.moveUp(2)
hero.moveRight()`,
  codeLanguage: 'python'
})

testCases.push({
  name: 'Python, String arguments',
  code: `
hero.say("Hello")
hero.say('World')`,
  codeLanguage: 'python'
})

testCases.push({
  name: 'Python, Variable',
  code: `
greeting = "Hello"
hero.say(greeting)
hero.say("World")`,
  codeLanguage: 'python'
})

testCases.push({
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

testCases.push({
  name: 'Python, Legal thing to do',
  code: `
hero.moveLeft(hero.attackDamage)
`,
  codeLanguage: 'python'
})

testCases.push({
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

testCases.push({
  name: 'Python, String concatenation',
  code: `
    hero.say("I'm glad my health is " + hero.health + ' and not potato.')
`,
  codeLanguage: 'python'
})

testCases.push({
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

testCases.push({
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

testCases.push({
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

testCases.push({
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

testCases.push({
  name: 'Python, Ternary Operator',
  code: `
foo = 'bar' if True else 'baz'
hero.say(foo)
`,
  codeLanguage: 'python'
})

testCases.push({
  name: 'Python, Functions - Arrow',
  code: `
baz = lambda x: x * x

hero.say(baz(baz(baz(2))))
`,
  codeLanguage: 'python'
})

testCases.push({
  name: 'Python, Arrays - Push',
  code: `
list = ['a', 'b']
list.append(c)
`,
  codeLanguage: 'python'
})

testCases.push({
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

testCases.push({
  name: 'Python, For loops - Array',
  code: `
for i in [1, 2, 3]:
    hero.say(i)
`,
  codeLanguage: 'python'
})

testCases.push({
  name: 'Python, For loops - Array - String',
  code: `
for i in 'abc':
    hero.say(i)
`,
  codeLanguage: 'python'
})

testCases.push({
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

testCases.push({
  name: 'D',
  code: `
// Grab all the gems using your movement commands.

hero.moveRight();
d
`,
  codeLanguage: 'javascript'
})

testCases.push({
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

propertyEntryGroups = {
  Deflector: {
    props: [
      { args: [{ type: 'object', name: 'target' }], type: 'function', name: 'bash', owner: 'this', ownerName: 'hero' },
      { owner: 'this', type: 'function', name: 'shield', ownerName: 'hero' }
    ]
  },
  'Sword of the Temple Guard': {
    props: [
      { args: [{ default: '', type: 'object', name: 'target' }], type: 'function', name: 'attack', owner: 'this', ownerName: 'hero' },
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
      { name: 'findEnemies', type: 'function', owner: 'this', ownerName: 'hero' },
      { name: 'findFriends', type: 'function', owner: 'this', ownerName: 'hero' },
      { name: 'findItems', type: 'function', owner: 'this', ownerName: 'hero' },
      { name: 'findNearest', type: 'function', args: [{ name: 'units', type: 'array' }], owner: 'this', ownerName: 'hero' },
      { name: 'findNearestEnemy', type: 'function', owner: 'this', ownerName: 'hero' },
      { name: 'findNearestItem', type: 'function', owner: 'this', ownerName: 'hero' },
      { name: 'findEnemyMissiles', type: 'function', owner: 'this', ownerName: 'hero' },
      { name: 'findFriendlyMissiles', type: 'function', owner: 'this', ownerName: 'hero' },
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
      { type: 'function', name: 'moveUp', args: [{ name: 'steps', type: 'number', default: 1 }], owner: 'this', ownerName: 'hero' }]
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
      { owner: 'this', args: [{ default: '', type: 'string', name: 'summonType' }], type: 'function', name: 'summon', ownerName: 'hero' }]
  },
  "Master's Flags": {
    props: [
      { name: 'addFlag', type: 'function', owner: 'this', ownerName: 'hero' },
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
